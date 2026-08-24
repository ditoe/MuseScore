/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * MuseScore Studio
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore Limited and others
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "lyrics.h"
#include "system.h"

#include "types/translatablestring.h"

#include "../editing/textedit.h"
#include "../editing/undo.h"

#include "measure.h"
#include "navigate.h"
#include "score.h"
#include "segment.h"
#include "staff.h"
#include "text.h"
#include "utils.h"

#include "log.h"

using namespace mu;
using namespace mu::engraving;

namespace mu::engraving {
//---------------------------------------------------------
//   lyricsElementStyle
//---------------------------------------------------------

static const ElementStyle lyricsElementStyle {
    { Sid::lyricsPlacement, Pid::PLACEMENT },
    { Sid::lyricsAvoidBarlines, Pid::AVOID_BARLINES },
};

//---------------------------------------------------------
//   Lyrics
//---------------------------------------------------------

Lyrics::Lyrics(ChordRest* parent)
    : TextBase(ElementType::LYRICS, parent, TextStyleType::LYRICS_ODD, ElementFlag::ON_STAFF)
{
    m_separator  = 0;
    initElementStyle(&lyricsElementStyle);
    m_verse         = 0;
    m_move_lyrics = 0;
    m_ticks      = Fraction(0, 1);
    m_syllabic   = LyricsSyllabic::SINGLE;
}

Lyrics::Lyrics(const Lyrics& l)
    : TextBase(l)
{
    m_verse        = l.m_verse;
    m_move_lyrics = l.m_move_lyrics;
    m_ticks     = l.m_ticks;
    m_syllabic  = l.m_syllabic;
    m_separator = 0;
}

Lyrics::~Lyrics()
{
    if (m_separator) {
        remove(m_separator);
    }
}

TranslatableString Lyrics::subtypeUserName() const
{
    return TranslatableString("engraving", "Verse %1").arg(m_verse + 1);
}

//---------------------------------------------------------
//   add
//---------------------------------------------------------

void Lyrics::add(EngravingItem* el)
{
    if (el->isLyricsLine()) {
        LyricsLine* separator = toLyricsLine(el);
        m_separator = separator;
        score()->addUnmanagedSpanner(separator);
    } else {
        LOGD("Lyrics::add: unknown element %s", el->typeName());
    }
}

//---------------------------------------------------------
//   remove
//---------------------------------------------------------

void Lyrics::remove(EngravingItem* el)
{
    if (el->isLyricsLine()) {
        // only if separator still exists and is the right one
        if (m_separator && el == m_separator) {
            // Lyrics::remove() and LyricsLine::removeUnmanaged() call each other;
            // be sure each finds a clean context
            LyricsLine* separ = m_separator;
            m_separator = 0;
            separ->removeUnmanaged();
        }
    } else {
        LOGD("Lyrics::remove: unknown element %s", el->typeName());
    }
}

//---------------------------------------------------------
//   isMelisma
//---------------------------------------------------------

bool Lyrics::isMelisma() const
{
    // entered as melisma using underscore?
    if (m_ticks > Fraction(0, 1)) {
        return true;
    }

    // hyphenated?
    // if so, it is a melisma only if there is no lyric in same verse on next CR
    if (m_separator && (m_syllabic == LyricsSyllabic::BEGIN || m_syllabic == LyricsSyllabic::MIDDLE)) {
        // find next CR and check for existence of lyric in same verse and placement (in any voice)
        const ChordRest* cr = chordRest();
        if (cr) {
            const Segment* s = cr->segment()->next1();
            const track_idx_t strack = staffIdx() * VOICES;
            const track_idx_t etrack = strack + VOICES;
            const track_idx_t lyrTrack = track();
            const ChordRest* lyrVoiceNextCR = s ? s->nextChordRest(lyrTrack) : nullptr;
            for (track_idx_t track = strack; track < etrack; ++track) {
                const ChordRest* trackNextCR = s ? s->nextChordRest(track) : nullptr;
                if (trackNextCR) {
                    if (lyrTrack != track && lyrVoiceNextCR
                        && !lyrVoiceNextCR->lyrics(m_verse, placement()) && lyrVoiceNextCR->tick() < trackNextCR->tick()) {
                        // There is an intermediary note in a different voice, this is a melisma
                        return true;
                    }
                    if (trackNextCR->lyrics(m_verse, placement())) {
                        // Next note has lyrics, not a melisma just a dash
                        return false;
                    }
                }
            }
            return true;
        }
    }

    // default - not a melisma
    return false;
}

//---------------------------------------------------------
//   paste
//---------------------------------------------------------

void Lyrics::paste(EditData& ed, const String& txt)
{
    if (txt.startsWith('<') && txt.contains('>')) {
        TextBase::paste(ed, txt);
        return;
    }

    String regex = String(u"[^\\S") + Char(0xa0) + Char(0x202F) + u"]+";
    StringList sl = txt.split(std::regex(regex.toStdString()), muse::SkipEmptyParts);
    if (sl.empty()) {
        return;
    }

    StringList hyph = sl.at(0).split(u'-');
    score()->startCmd(TranslatableString("undoableAction", "Paste lyrics"));

    deleteSelectedText(ed);

    if (hyph.size() > 1) {
        score()->undo(new InsertText(cursorFromEditData(ed), hyph[0]), &ed);
        hyph.removeAt(0);
        sl[0] =  hyph.join(u"-");
    } else if (sl.size() > 1 && sl[1] == u"-") {
        score()->undo(new InsertText(cursorFromEditData(ed), sl[0]), &ed);
        sl.removeAt(0);
        sl.removeAt(0);
    } else if (sl[0].startsWith(u"_")) {
        sl[0].remove(0, 1);
        if (sl[0].isEmpty()) {
            sl.removeAt(0);
        }
    } else if (sl[0].contains(u"_")) {
        size_t p = sl[0].indexOf(u'_');
        score()->undo(new InsertText(cursorFromEditData(ed), sl[0]), &ed);
        sl[0] = sl[0].mid(p + 1);
        if (sl[0].isEmpty()) {
            sl.removeAt(0);
        }
    } else if (sl.size() > 1 && sl[1] == "_") {
        score()->undo(new InsertText(cursorFromEditData(ed), sl[0]), &ed);
        sl.removeAt(0);
        sl.removeAt(0);
    } else {
        score()->undo(new InsertText(cursorFromEditData(ed), sl[0]), &ed);
        sl.removeAt(0);
    }

    score()->endCmd();
}

//---------------------------------------------------------
//   endTick
//---------------------------------------------------------

Fraction Lyrics::endTick() const
{
    return segment()->tick() + ticks();
}

//---------------------------------------------------------
//   acceptDrop
//---------------------------------------------------------

bool Lyrics::acceptDrop(EditData& data) const
{
    return data.dropElement->isText() || TextBase::acceptDrop(data);
}

//---------------------------------------------------------
//   drop
//---------------------------------------------------------

EngravingItem* Lyrics::drop(EditData& data)
{
    ElementType type = data.dropElement->type();
    if (type == ElementType::SYMBOL || type == ElementType::FSYMBOL) {
        TextBase::drop(data);
        return 0;
    }
    if (!data.dropElement->isText()) {
        delete data.dropElement;
        data.dropElement = 0;
        return 0;
    }
    Text* e = toText(data.dropElement);
    e->setParent(this);
    score()->undoAddElement(e);
    return e;
}

bool Lyrics::isEditAllowed(EditData& ed) const
{
    if (isTextNavigationKey(ed.key, ed.modifiers)) {
        return false;
    }

    static const std::set<KeyboardModifiers> navigationModifiers {
        NoModifier,
        KeypadModifier,
        ShiftModifier
    };

    if (navigationModifiers.find(ed.modifiers) != navigationModifiers.end()) {
        static const std::set<int> navigationKeys {
            Key_Underscore,
            Key_Minus,
            Key_Enter,
            Key_Return,
            Key_Up,
            Key_Down
        };

        if (navigationKeys.find(ed.key) != navigationKeys.end()) {
            return false;
        }
    }

    if (ed.key == Key_Left || ed.key == Key_Backspace) {
        return cursor()->column() != 0 || cursor()->hasSelection();
    }

    if (ed.key == Key_Right) {
        bool cursorInLastColumn = cursor()->column() == cursor()->curLine().columns();
        return !cursorInLastColumn || cursor()->hasSelection();
    }

    return TextBase::isEditAllowed(ed);
}

void Lyrics::adjustPrevious()
{
    Lyrics* prev = prevLyrics(toLyrics(this));
    if (prev) {
        // search for lyric spanners to split at this point if necessary
        if (prev->tick() + prev->ticks() >= tick()) {
            // the previous lyric has a spanner attached that goes through this one
            // we need to shorten it
            Segment* s = score()->tick2segment(tick());
            if (s) {
                s = s->prev1(SegmentType::ChordRest);
                if (s->tick() > prev->tick()) {
                    prev->undoChangeProperty(Pid::LYRIC_TICKS, s->tick() - prev->tick());
                } else {
                    prev->undoChangeProperty(Pid::LYRIC_TICKS, Fraction::eps());
                }
                prev->setNeedRemoveInvalidSegments();
                prev->triggerLayout();
            }
        }
    }
}

void Lyrics::setNeedRemoveInvalidSegments()
{
    // Allow "invalid" segments when there is a following repeat item

    const Measure* meas = measure();
    const ChordRest* separatorEndChord = m_separator ? toChordRest(m_separator->endElement()) : nullptr;
    const ChordRest* lastChordRest = meas ? meas->lastChordRest(track()) : nullptr;
    const bool endChordIsLastInMeasure = separatorEndChord == lastChordRest;
    const bool hasFollowingJump = lastChordRest ? lastChordRest->hasFollowingJumpItem() : false;

    if (endChordIsLastInMeasure && hasFollowingJump) {
        return;
    }
    m_needRemoveInvalidSegments = true;
}

//---------------------------------------------------------
//   endEdit
//---------------------------------------------------------

void Lyrics::endEdit(EditData& ed)
{
    TextBase::endEdit(ed);

    triggerLayout();
    if (m_separator) {
        m_separator->triggerLayout();
    }
}

//---------------------------------------------------------
//   removeFromScore
//---------------------------------------------------------

void Lyrics::removeFromScore()
{
    if (m_ticks.isNotZero()) {
        // clear melismaEnd flag from end cr
        ChordRest* ecr = score()->findCR(endTick(), track());
        if (ecr) {
            ecr->setMelismaEnd(false);
        }
    }

    if (!plainText().isEmpty()) {
        PartialLyricsLine* partialDash = findPrevPartialLyricsLineDash(this);
        if (partialDash) {
            score()->undoRemoveElement(partialDash);
        }
    }

    if (m_separator) {
        m_separator->removeUnmanaged();
        delete m_separator;
        m_separator = 0;
    }
    Lyrics* prev = prevLyrics(this);
    if (prev) {
        // check to make sure we haven't created an invalid segment by deleting this lyric
        prev->setNeedRemoveInvalidSegments();
    }
}

//---------------------------------------------------------
//   getProperty
//---------------------------------------------------------

PropertyValue Lyrics::getProperty(Pid propertyId) const
{
    switch (propertyId) {
    case Pid::SYLLABIC:
        return int(m_syllabic);
    case Pid::LYRIC_TICKS:
        return m_ticks;
    case Pid::VERSE:
        return m_verse;
    case Pid::AVOID_BARLINES:
        return m_avoidBarlines;
    case Pid::LYRICS_STAFF_SHIFT:
        return m_move_lyrics;
    default:
        return TextBase::getProperty(propertyId);
    }
}

//---------------------------------------------------------
//   setProperty
//---------------------------------------------------------

bool Lyrics::setProperty(Pid propertyId, const PropertyValue& v)
{
    ChordRest* scr = nullptr;
    ChordRest* ecr = nullptr;

    switch (propertyId) {
    case Pid::PLACEMENT:
    {
        PlacementV newVal = v.value<PlacementV>();
        if (newVal != placement()) {
            if (Lyrics* l = prevLyrics(this)) {
                l->setNeedRemoveInvalidSegments();
            }
            if (nextLyrics(this)) {
                setNeedRemoveInvalidSegments();
            }
            m_move_lyrics = 0;
            setPlacement(newVal);
        }
    }
    break;
    case Pid::SYLLABIC:
        m_syllabic = LyricsSyllabic(v.toInt());
        break;
    case Pid::LYRIC_TICKS:
        if (m_ticks.isNotZero()) {
            // clear melismaEnd flag from previous end cr
            // this might be premature, as there may be other melismas ending there
            // but flag will be generated correctly on layout
            // TODO: after inserting a measure,
            // endTick info is wrong.
            // Somehow we need to fix this.
            // See https://musescore.org/en/node/285304 and https://musescore.org/en/node/311289
            ecr = score()->findCR(endTick(), track());
            if (ecr) {
                ecr->setMelismaEnd(false);
            }
        }
        scr = score()->findCR(tick(), track());
        m_ticks = v.value<Fraction>();
        if (scr && m_ticks <= scr->ticks()) {
            // if no ticks, we have to relayout in order to remove invalid melisma segments
            setNeedRemoveInvalidSegments();
        }
        break;
    case Pid::VERSE: {
        if (Lyrics* l = prevLyrics(this)) {
            l->setNeedRemoveInvalidSegments();
        }
        bool followTextStyle = getProperty(Pid::TEXT_STYLE) == propertyDefault(Pid::TEXT_STYLE);
        m_verse = v.toInt();
        if (followTextStyle) {
            setProperty(Pid::TEXT_STYLE, propertyDefault(Pid::TEXT_STYLE));
        }
        break;
    }
    case Pid::AVOID_BARLINES:
        m_avoidBarlines = v.toBool();
        break;
    case Pid::VISIBLE:
        setVisible(v.toBool());
        break;
    case Pid::LYRICS_STAFF_SHIFT:    
        m_move_lyrics = normalizeLyricsStaffShift(v.toInt(), m_move_lyrics);
        break;
    default:
        if (!TextBase::setProperty(propertyId, v)) {
            return false;
        }
        break;
    }
    triggerLayout();
    return true;
}

//---------------------------------------------------------
//   propertyDefault
//---------------------------------------------------------

PropertyValue Lyrics::propertyDefault(Pid id) const
{
    switch (id) {
    case Pid::TEXT_STYLE:
        return isEven() ? TextStyleType::LYRICS_EVEN : TextStyleType::LYRICS_ODD;
    case Pid::PLACEMENT:
        return style().styleV(Sid::lyricsPlacement);
    case Pid::SYLLABIC:
        return int(LyricsSyllabic::SINGLE);
    case Pid::LYRIC_TICKS:
        return Fraction(0, 1);
    case Pid::VERSE:
        return 0;
    case Pid::AVOID_BARLINES:
        return style().styleB(Sid::lyricsAvoidBarlines);
    case Pid::POSITION:
    case Pid::LYRICS_STAFF_SHIFT:
        return 0;
    case Pid::ALIGN:
        if (isMelisma()) {
            return style().styleV(Sid::lyricsMelismaAlign).value<Align>().horizontal;
        }
    // fall through
    default:
        return TextBase::propertyDefault(id);
    }
}

void Lyrics::triggerLayout() const
{
    if (m_separator) {
        // The separator may extend to next system(s), so we must use Spanner::triggerLayout()
        m_separator->triggerLayout();
    } else {
        // In this case is ok to use EngravingItem::triggerLayout()
        EngravingItem::triggerLayout();
    }
}

double Lyrics::yRelativeToStaff() const
{
    const double yOff = staffOffsetY();
    return pos().y() + chordRest()->pos().y() + yOff;
}

void Lyrics::setYRelativeToStaff(double y)
{
    const double yOff = staffOffsetY();
    mutldata()->setPosY(y - chordRest()->pos().y() - yOff);
}

//---------------------------------------------------------
//   forAllLyrics
//---------------------------------------------------------

void Score::forAllLyrics(std::function<void(Lyrics*)> f)
{
    for (Segment* s = firstSegment(SegmentType::ChordRest); s; s = s->next1(SegmentType::ChordRest)) {
        for (EngravingItem* e : s->elist()) {
            if (e) {
                for (Lyrics* l : toChordRest(e)->lyrics()) {
                    f(l);
                }
            }
        }
    }
}

//---------------------------------------------------------
//   undoChangeProperty
//---------------------------------------------------------

void Lyrics::undoChangeProperty(Pid id, const PropertyValue& v, PropertyFlags ps)
{
    if (id == Pid::VERSE && verse() != v.toInt()) {
        PartialLyricsLine* prevPartial = findPrevPartialLyricsLineDash(this);

        for (Lyrics* l : chordRest()->lyrics()) {
            if (l->verse() == v.toInt()) {
                // verse already exists, swap
                l->TextBase::undoChangeProperty(id, verse(), ps);
                const PlacementV p = l->placement();
                l->TextBase::undoChangeProperty(Pid::PLACEMENT, placement(), ps);
                TextBase::undoChangeProperty(Pid::PLACEMENT, p, ps);
                break;
            }
        }
        TextBase::undoChangeProperty(id, v, ps);
        if (prevPartial && prevPartial->verse() != v.toInt()) {
            // Skip logic to update Lyrics by calling parent class
            prevPartial->LyricsLine::undoChangeProperty(id, v, ps);
        }
        return;
    } else if (id == Pid::VISIBLE && separator()) {
        separator()->undoChangeProperty(Pid::VISIBLE, v.toBool(), ps);
    }
    if (id == Pid::LYRICS_STAFF_SHIFT && move_lyrics() != v.toInt()) {
        //for (Lyrics* l : chordRest()->lyrics()) {
        //    if (l->move_lyrics() == v.toInt()) {
        //        // verse already exists, swap
        //        l->TextBase::undoChangeProperty(id, move_lyrics(), ps);
        //        PlacementV p = l->placement();
        //        l->TextBase::undoChangeProperty(Pid::PLACEMENT, int(placement()), ps);
        //        TextBase::undoChangeProperty(Pid::PLACEMENT, int(p), ps);
        //        break;
        //    }
        //}
        TextBase::undoChangeProperty(id, v, ps);
        return;
    }

    TextBase::undoChangeProperty(id, v, ps);
}

//---------------------------------------------------------
//   removeInvalidSegments
//
// Remove lyric-final melisma lines and reset the alignment of the lyric
//---------------------------------------------------------

void Lyrics::removeInvalidSegments()
{
    m_needRemoveInvalidSegments = false;
    if (m_separator && isMelisma() && m_ticks < m_separator->startCR()->ticks()) {
        setTicks(Fraction(0, 1));
        m_separator->setTicks(Fraction(0, 1));
        m_separator->removeUnmanaged();
        m_separator = nullptr;
        setPosition(propertyDefault(Pid::POSITION).value<AlignH>());
        if (m_syllabic == LyricsSyllabic::BEGIN || m_syllabic == LyricsSyllabic::SINGLE) {
            undoChangeProperty(Pid::SYLLABIC, int(LyricsSyllabic::SINGLE));
        } else {
            undoChangeProperty(Pid::SYLLABIC, int(LyricsSyllabic::END));
        }
    }
}
//---------------------------------------------------------
//   layout3
//    compute vertical position
//---------------------------------------------------------

void Lyrics::layout3()
{
    Measure* measure = segment()->measure();
    System* system = measure ? measure->system() : nullptr;

    if (!system) {
        return;
    }

    if (!isValidLyricsStaffShift(m_move_lyrics)) {
        m_move_lyrics = normalizeLyricsStaffShift(m_move_lyrics, m_move_lyrics - 1);
    }

    const int sourceStaff =
        static_cast<int>(staffIdx());

    const int targetStaff = placeBelow()
        ? sourceStaff + m_move_lyrics
        : sourceStaff - m_move_lyrics;

    if (targetStaff < 0
        || targetStaff >= static_cast<int>(system->staves().size())) {
        return;
    }

    const SysStaff* sourceSysStaff =
        system->staff(static_cast<size_t>(sourceStaff));

    const SysStaff* targetSysStaff =
        system->staff(static_cast<size_t>(targetStaff));

    if (!sourceSysStaff || !targetSysStaff
        || !targetSysStaff->show()) {
        return;
    }

    const qreal y1 =
        sourceSysStaff->get_distanceFirstStaff();

    const qreal y2 =
        targetSysStaff->get_distanceFirstStaff();

    mutldata()->moveY(placeBelow() ? y2 - y1 : y1 - y2);
}
int Lyrics::normalizeLyricsStaffShift(int requestedShift, int previousShift)
{
    requestedShift = std::max(requestedShift, 0);

    if (!this || !explicitParent() || !segment() || !measure() || !measure()->system()) {
        return requestedShift;
    }

    if (isValidLyricsStaffShift(requestedShift)) {
        return requestedShift;
    }

    // Der Benutzer zählt nach oben oder nach unten.
    const int direction =
        requestedShift > previousShift ? 1 : -1;

    const int staffCount = static_cast<int>(
        measure()->system()->staves().size());

    if (direction > 0) {
        // Beispiel: 1 -> 2 -> 3
        for (int shift = requestedShift + 1;
            shift < staffCount;
            ++shift) {
            if (isValidLyricsStaffShift(shift)) {
                return shift;
            }
        }
    }
    else {
        // Beispiel: 3 -> 2 -> 1
        for (int shift = requestedShift - 1;
            shift >= 0;
            --shift) {
            if (isValidLyricsStaffShift(shift)) {
                return shift;
            }
        }
    }

    // Kein Wert in Änderungsrichtung vorhanden:
    // auf den maximalen gültigen Wert zurückfallen.
    for (int shift = staffCount - 1;
        shift >= 0;
        --shift) {
        if (isValidLyricsStaffShift(shift)) {
            return shift;
        }
    }

    return 0;
}

bool Lyrics::isVisibleStaff(const System* system, int staffIdx)
{
    if (!system || staffIdx < 0
        || staffIdx >= static_cast<int>(system->staves().size())) {
        return false;
    }

    const SysStaff* sysStaff = system->staff(static_cast<size_t>(staffIdx));
    return sysStaff && sysStaff->show();
}
bool Lyrics::isValidLyricsStaffShift(int shift)
{
    if (!this || !measure()
        || !measure()->system()) {
        return false;
    }

    if (shift < 0) {
        return false;
    }

    const System* system = measure()->system();
    const int sourceStaff = static_cast<int>(staffIdx());
    const int targetStaff = placeBelow()
        ? sourceStaff + shift
        : sourceStaff - shift;

    if (targetStaff < 0
        || targetStaff >= static_cast<int>(system->staves().size())) {
        return false;
    }

    const SysStaff* sysStaff =
        system->staff(static_cast<size_t>(targetStaff));

    return sysStaff && sysStaff->show();
}

//---------------------------------------------------------
//   layout3
//    compute vertical position
//---------------------------------------------------------

void LyricsLineSegment::layout3()
{
    qreal y = 0.0;
    if (lyrics()) {
        y = lyrics()->yRelativeToStaff();
        y += baseLineShift();
        y -= offset().y();
        mutldata()->setPosY(y);
        return;
    }
    const LyricsLine* line = lyricsLine();

    int lyricsShift = 0;

    if (line->isPartialLyricsLine()) {
        lyricsShift = toPartialLyricsLine(line)->move_lyrics();
    }
    else {
        return;
    }

    System* sys = system();

    if (!sys) {
        return;
    }

    if (placeBelow()) {
        int shiftStaff = static_cast<int>(staffIdx()) + lyricsShift;

        if (shiftStaff >= static_cast<int>(score()->nstaves())) {
            shiftStaff = static_cast<int>(score()->nstaves()) - 1;
        }

        const qreal y1 =
            sys->staff(staffIdx())->get_distanceFirstStaff();

        const qreal y2 =
            sys->staff(shiftStaff)->get_distanceFirstStaff();

        qreal y = mutldata()->pos().y();
        y += y2 - y1;
        mutldata()->setPosY(y);
    }
    else {
        int shiftStaff = static_cast<int>(staffIdx()) - lyricsShift;

        if (shiftStaff < 0) {
            shiftStaff = 0;
        }

        const qreal y1 =
            sys->staff(staffIdx())->get_distanceFirstStaff();

        const qreal y2 =
            sys->staff(shiftStaff)->get_distanceFirstStaff();

        mutldata()->moveY(y1 - y2);
    }
}
}
