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

#ifndef __HOOK_H__
#define __HOOK_H__

#include "symbol.h"

namespace Ms {

class Chord;

//---------------------------------------------------------
//   @@ Hook
//---------------------------------------------------------

class Hook final : public Symbol {
      int _hookType { 0 };

      qreal _cipherLineWidht;
      qreal _cipherLineThick;
      qreal _cipherLineSpace;
      qreal _cipherHigthLine;
      qreal _cipherHigth;

   public:
      Hook(Score* = 0);

      Hook* clone() const override        { return new Hook(*this); }
      qreal mag() const override          { return parent()->mag(); }
      ElementType type() const override   { return ElementType::HOOK; }
      void setHookType(int v);
      void setCipherHookDimension(qreal widht, qreal higth) {_cipherLineWidht = widht; _cipherHigth = higth;}
      int hookType() const                { return _hookType; }
      void layout() override;
      void draw(QPainter*) const override;
      Chord* chord() const                { return (Chord*)parent(); }
      };


}     // namespace Ms
#endif

