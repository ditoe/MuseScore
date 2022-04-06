#include "numeric.h"
#include "mscore.h"


namespace Ms {
//---------------------------------------------------------
//   textWidth
//---------------------------------------------------------

qreal numeric::textWidth(const QFont font, const QString string) const
      {
      qreal val;
      QFontMetricsF fm(font);
      val  = fm.width(string);
      return val;
      }
qreal numeric::textHeigth(const QFont font, const QString string) const
      {
      qreal val;
      QFontMetricsF fm(font);
      QRectF pos = fm.tightBoundingRect(string).translated(QPointF());
      val  = pos.height();
      return val;
      }
QRectF numeric::bbox(QFont font, QPointF pos, QString string)
      {
      QFontMetricsF fm(font);
      return fm.tightBoundingRect(string).translated(pos);
      }
void numeric::drawShap(QPainter *painter, QPointF pos, QFont font) const
      {
      QFont fontold = painter->font();
      painter->setFont(font);
      painter->drawText(pos, "♯");
      painter->setFont(fontold);
      }
void numeric::drawFlat(QPainter *painter, QPointF pos, QFont font) const
      {
      QFont fontold = painter->font();
      painter->setFont(font);
      painter->drawText(pos, "♭");
      painter->setFont(fontold);
      }

}
