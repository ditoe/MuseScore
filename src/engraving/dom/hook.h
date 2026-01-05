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

#ifndef MU_ENGRAVING_HOOK_H
#define MU_ENGRAVING_HOOK_H

#include "symbol.h"

#include "global/allocator.h"

namespace mu::engraving {
class Chord;

class Hook final : public Symbol
{
    OBJECT_ALLOCATOR(engraving, Hook)
    DECLARE_CLASSOF(ElementType::HOOK)

public:
    Hook(Chord* parent = 0);

    Hook* clone() const override { return new Hook(*this); }
    double mag() const override { return parentItem()->mag(); }
    EngravingItem* elementBase() const override;

    void setHookType(int v);
    int hookType() const { return m_hookType; }

    Chord* chord() const { return toChord(explicitParent()); }
    PointF smuflAnchor() const;

    //! @p index: the number of flags (positive: upwards, negative: downwards)
    //! @p straight: whether to use straight flags
    static SymId symIdForHookIndex(int index, bool straight);
    void setCipherDimension(qreal width, qreal higth) { m_cipherWidth = width; m_cipherHeigth = higth; }
    void set_cipherLineWidth(qreal r) { m_cipherLineWidth = r; }
    void set_cipherLineThick(qreal r) { m_cipherLineThick = r; }
    void set_cipherLineSpace(qreal r) { m_cipherLineSpace = r; }
    void set_cipherHeigthLine(qreal r) { m_cipherHeigthLine = r; }
    void set_cipherHeigth(qreal r) { m_cipherHeigth = r; }
    void set_cipherWidth(qreal r) { m_cipherWidth = r; }
    void set_cipherLine(LineF l) { m_cipherLine = l; }
    qreal get_cipherLineWidth() const { return m_cipherLineWidth; }
    qreal get_cipherLineThick() const { return m_cipherLineThick; }
    qreal get_cipherLineSpace() const { return m_cipherLineSpace; }
    qreal get_cipherHeigthLine() const { return m_cipherHeigthLine; }
    qreal get_cipherHeigth() const { return m_cipherHeigth; }
    qreal get_cipherWidth() const { return m_cipherWidth; }
    LineF get_cipherLine() const { return m_cipherLine; }

private:
    int m_hookType = 0;
    qreal m_cipherLineWidth;
    qreal m_cipherLineThick;
    qreal m_cipherLineSpace;
    qreal m_cipherHeigthLine;
    qreal m_cipherHeigth;
    qreal m_cipherWidth;
    LineF m_cipherLine;
};
} // namespace mu::engraving
#endif
