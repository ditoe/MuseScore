/*
 * SPDX-License-Identifier: GPL-3.0-only
 * MuseScore-Studio-CLA-applies
 *
 * MuseScore Studio
 * Music Composition & Notation
 *
 * Copyright (C) 2021 MuseScore Limited
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

#ifndef MU_ENGRAVING_KEYSIG_H
#define MU_ENGRAVING_KEYSIG_H

#include "key.h"
#include "engravingitem.h"

namespace mu::engraving {
class Factory;
class Segment;

//---------------------------------------------------------------------------------------
//   @@ KeySig
///    The KeySig class represents a Key Signature on a staff
//
//   @P showCourtesy  bool  show courtesy key signature for this sig if appropriate
//---------------------------------------------------------------------------------------

class KeySig final : public EngravingItem
{
    OBJECT_ALLOCATOR(engraving, KeySig)
    DECLARE_CLASSOF(ElementType::KEYSIG)

    M_PROPERTY2(bool, isCourtesy, setIsCourtesy, false)

public:

    KeySig* clone() const override { return new KeySig(*this); }

    bool acceptDrop(EditData&) const override;
    EngravingItem* drop(EditData&) override;

    double mag() const override;

    //@ sets the key of the key signature (concert key and transposing key)
    void setKey(Key cKey, Key tKey);
    void setKey(Key cKey);

    Segment* segment() const { return (Segment*)explicitParent(); }
    Measure* measure() const { return explicitParent() ? (Measure*)explicitParent()->explicitParent() : nullptr; }

    //@ returns the key of the actual key signature (from -7 (flats) to +7 (sharps) )
    Key key() const { return m_sig.key(); }
    //@ returns the key of the concert key signature
    Key concertKey() const { return m_sig.concertKey(); }
    const std::vector<CustDef>& customKeyDefs() const { return m_sig.customKeyDefs(); }
    int degInKey(int degree) const { return m_sig.degInKey(degree); }
    SymId symInKey(SymId sym, int degree) const { return m_sig.symInKey(sym, degree); }
    bool isCustom() const { return m_sig.custom(); }
    bool isAtonal() const { return m_sig.isAtonal(); }
    bool isChange() const;
    const KeySigEvent& keySigEvent() const { return m_sig; }
    bool operator==(const KeySig&) const;
    void changeKeySigEvent(const KeySigEvent&);
    void setKeySigEvent(const KeySigEvent& e) { m_sig = e; }

    bool showCourtesy() const { return m_showCourtesy; }
    void setShowCourtesy(bool v) { m_showCourtesy = v; }
    void undoSetShowCourtesy(bool v);

    KeyMode mode() const { return m_sig.mode(); }
    void setMode(KeyMode v) { m_sig.setMode(v); }
    void undoSetMode(KeyMode v);

    PointF staffOffset() const override;

    bool hideNaturals() const { return m_hideNaturals; }
    void setHideNaturals(bool hide) { m_hideNaturals = hide; }

    void setForInstrumentChange(bool forInstrumentChange) { m_sig.setForInstrumentChange(forInstrumentChange); }
    bool forInstrumentChange() const { return m_sig.forInstrumentChange(); }

    PropertyValue getProperty(Pid propertyId) const override;
    bool setProperty(Pid propertyId, const PropertyValue&) override;
    PropertyValue propertyDefault(Pid id) const override;

    EngravingItem* nextSegmentElement() override;
    EngravingItem* prevSegmentElement() override;
    String accessibleInfo() const override;

    int subtype() const override { return int(key()) + 7; }
    muse::TranslatableString subtypeUserName() const override;

    struct LayoutData : public EngravingItem::LayoutData {
        std::vector<KeySym> keySymbols;
        RectF cipherTextRect;
    };
    qreal cipherGetWidth(StaffType* cipher, String string) const;
    String getCipherString(int key, int d) const;
    String get_cipherString() const { return m_cipherString; }
    String get_cipherNoteString() const { return m_cipherNoteString; }
    muse::draw::Font cipherKeySigFont() const;
    qreal get_cipherReigthAdjust() { return m_cipherReigthAdjust; }
    qreal get_cipherLefthAdjust() { return m_cipherLeftAdjust; }
    qreal get_cipherHeigth() const { return m_cipherHeigth; }
    qreal get_cipherLeftAdjust() const { return m_cipherLeftAdjust; }
    qreal get_cipherNoteShift() const { return m_cipherNoteShift; }
    qreal get_cipherReigthAdjust() const { return m_cipherReigthAdjust; }
    int get_cipherAccidentalShift() const { return m_cipherAccidentalShift; }
    PointF get_cipherPoint() const { return m_cipherPoint; }
    PointF get_cipherNotePoint() const { return m_cipherNotePoint; }
    PointF get_cipherAccidentalPoint() const { return m_cipherAccidentalPoint; }
    PointF get_cipherNoteKlammerPoint() const { return m_cipherNoteKlammerPoint; }
    RectF get_cipherNoteRecht() const { return m_cipherNoteRecht; }
    RectF get_cipherNoteKlammerRecht() const { return m_cipherNoteKlammerRecht; }
    RectF get_cipherShape() const { return m_cipherShape; }
    bool get_cipherEnable() const { return m_cipherEnable; }
    bool get_cipherDrawNote()const { return m_cipherDrawNote; }
    void set_cipherNote(String note, int Accidental, qreal shift) {
        m_cipherNoteString = note;
        m_cipherAccidentalShift = Accidental;
        m_cipherNoteShift = shift;
    }
    void set_cipherHeigth(qreal r) { m_cipherHeigth = r; }
    void set_cipherLeftAdjust(qreal r) {m_cipherLeftAdjust = r; }
    void set_cipherReigthAdjust(qreal r) { m_cipherReigthAdjust = r; }
    void set_cipherEnable(bool b) { m_cipherEnable = b; }
    void set_cipherDrawNote(bool b) { m_cipherDrawNote = b; }
    void set_cipherString(String s) { m_cipherString = s; }
    void set_cipherNoteString(String s) { m_cipherNoteString = s; }
    void set_cipherPoint(PointF p) { m_cipherPoint = p; }
    void set_cipherNotePoint(PointF p) { m_cipherNotePoint = p; }
    void set_cipherAccidentalPoint(PointF p) { m_cipherAccidentalPoint = p; }
    void set_cipherNoteKlammerPoint(PointF p) { m_cipherNoteKlammerPoint = p; }
    void set_cipherNoteRecht(RectF r) { m_cipherNoteRecht = r; }
    void set_cipherNoteKlammerRecht(RectF r) { m_cipherNoteKlammerRecht = r; }
    void set_cipherShape(RectF r) { m_cipherShape = r; }
    void drawSharp(muse::draw::Painter* painter, const muse::PointF& pos, const muse::draw::Font& font) const;
    void drawFlat(muse::draw::Painter* painter, const muse::PointF& pos, const muse::draw::Font& font) const;


    DECLARE_LAYOUTDATA_METHODS(KeySig)

private:
    friend class Factory;

    KeySig(Segment* = 0);
    KeySig(const KeySig&);

    void addLayout(SymId sym, int line);

    bool m_showCourtesy;
    bool m_hideNaturals;       // used in layout to override score style (needed for the Continuous panel)
    KeySigEvent m_sig;
    String m_cipherString;
    String m_cipherNoteString;
    RectF m_cipherNoteRecht;
    RectF m_cipherNoteKlammerRecht;
    RectF m_cipherShape;
    int m_cipherAccidentalShift;
    qreal m_cipherNoteShift;
    qreal m_cipherHeigth;
    PointF m_cipherPoint;
    PointF m_cipherNotePoint;
    PointF m_cipherNoteKlammerPoint;
    PointF m_cipherAccidentalPoint;
    qreal m_cipherReigthAdjust;
    qreal m_cipherLeftAdjust;
    bool m_cipherEnable;
    bool m_cipherDrawNote;
    bool m_keyListSave = false;
    Fraction m_keyListSaveFraction = Fraction();
    KeySigEvent m_keyListSaveSig;
};
} // namespace mu::engraving
#endif
