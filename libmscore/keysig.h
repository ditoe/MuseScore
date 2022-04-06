//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2002-2011 Werner Schweer
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

#ifndef __KEYSIG_H__
#define __KEYSIG_H__

#include "key.h"
#include "element.h"
#include "groups.h"

namespace Ms {

class Sym;
class Segment;

//---------------------------------------------------------------------------------------
//   @@ KeySig
///    The KeySig class represents a Key Signature on a staff
//
//   @P showCourtesy  bool  show courtesy key signature for this sig if appropriate
//---------------------------------------------------------------------------------------

class KeySig final : public Element {
      bool _showCourtesy;
      bool _hideNaturals;     // used in layout to override score style (needed for the Continuous panel)
      KeySigEvent _sig;
      void addLayout(SymId sym, qreal x, int y);
      QString _numericString;
      QString _numericNoteString;
      QRectF _numericNoteRecht;
      QRectF _numericNoteKlammerRecht;
      QRectF _numericShape;
      int _numericAccidentalShift;
      qreal _numericNoteShift;
      qreal _numericHigth;
      QPointF _numericPoint;
      QPointF _numericNotePoint;
      QPointF _numericNoteKlammerPoint;
      QPointF _numericAccidentalPoint;
      qreal _numericReigthAdjust;
      qreal _numericLeftAdjust;
      bool _numericEnable;
      bool _numericDrawNote;
      bool _keyListSave = false;
      Fraction _keyListSaveFraction = Fraction();
      KeySigEvent _keyListSaveSig;

   public:
      KeySig(Score* = 0);
      KeySig(const KeySig&);
      void layout2();

      KeySig* clone() const override       { return new KeySig(*this); }
      void draw(QPainter*) const override;
      ElementType type() const override    { return ElementType::KEYSIG; }
      bool acceptDrop(EditData&) const override;
      Element* drop(EditData&) override;
      void layout() override;
      Shape shape() const override;
      qreal mag() const override;

      //@ sets the key of the key signature
      Q_INVOKABLE void setKey(Key);

      Segment* segment() const            { return (Segment*)parent(); }
      Measure* measure() const            { return parent() ? (Measure*)parent()->parent() : nullptr; }
      void write(XmlWriter&) const override;
      void read(XmlReader&) override;
      //@ returns the key of the key signature (from -7 (flats) to +7 (sharps) )
      Q_INVOKABLE Key key() const         { return _sig.key(); }
      bool isCustom() const               { return _sig.custom(); }
      bool isAtonal() const               { return _sig.isAtonal(); }
      bool isChange() const;
      KeySigEvent keySigEvent() const     { return _sig; }
      bool operator==(const KeySig&) const;
      void changeKeySigEvent(const KeySigEvent&);
      void setKeySigEvent(const KeySigEvent& e)      { _sig = e; }

      bool showCourtesy() const           { return _showCourtesy; }
      void setShowCourtesy(bool v)        { _showCourtesy = v;    }
      void undoSetShowCourtesy(bool v);

      KeyMode mode() const                { return _sig.mode(); }
      void setMode(KeyMode v)             { _sig.setMode(v); }
      void undoSetMode(KeyMode v);

      void setHideNaturals(bool hide)     { _hideNaturals = hide; }

      void setForInstrumentChange(bool forInstrumentChange) { _sig.setForInstrumentChange(forInstrumentChange); }
      bool forInstrumentChange() const    { return _sig.forInstrumentChange(); }

      QVariant getProperty(Pid propertyId) const override;
      bool setProperty(Pid propertyId, const QVariant&) override;
      QVariant propertyDefault(Pid id) const override;

      Element* nextSegmentElement() override;
      Element* prevSegmentElement() override;
      QString accessibleInfo() const override;

      qreal numericGetWidth(StaffType* numeric, QString string) const;
      qreal get_numericReigthAdjust()      { return _numericReigthAdjust; }
      qreal get_numericLefthAdjust()      { return _numericLeftAdjust; }
      void set_numericNote(QString note, int Accidental, qreal shift)      { _numericNoteString = note;
                                                                             _numericAccidentalShift = Accidental;
                                                                             _numericNoteShift = shift; }

      SymId convertFromOldId(int val) const;
      };

extern const char* keyNames[];

}     // namespace Ms
#endif

