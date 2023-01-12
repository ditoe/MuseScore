#include "cipher.h"
#include "mscore.h"


namespace Ms {
//---------------------------------------------------------
//   textWidth
//---------------------------------------------------------

qreal cipher::textWidth(const QFont font, const QString string) const
      {
      qreal val;
      QFontMetricsF fm(font);
      val  = fm.width(string);
      return val;
      }
qreal cipher::textHeigth(const QFont font, const QString string) const
      {
      qreal val;
      QFontMetricsF fm(font);
      QRectF pos = fm.tightBoundingRect(string).translated(QPointF());
      val  = pos.height();
      return val;
      }
QRectF cipher::bbox(QFont font, QPointF pos, QString string)
      {
      QFontMetricsF fm(font);
      return fm.tightBoundingRect(string).translated(pos);
      }
void cipher::drawShap(QPainter *painter, QPointF pos, QFont font) const
      {
      QFont fontold = painter->font();
      painter->setFont(font);
      painter->drawText(pos, "♯");
      painter->setFont(fontold);
      }
void cipher::drawFlat(QPainter *painter, QPointF pos, QFont font) const
      {
      QFont fontold = painter->font();
      painter->setFont(font);
      painter->drawText(pos, "♭");
      painter->setFont(fontold);
      }

}
