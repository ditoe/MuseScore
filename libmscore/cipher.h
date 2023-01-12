#ifndef CIPHER_H
#define CIPHER_H


namespace Ms {


class cipher
      {

      qreal _relativeSize;
	  QFont _FretFont;
public:
      qreal textWidth(const QFont font, const QString string) const;
      qreal textHeigth(const QFont font, const QString string) const;

      void set_relativeSize(qreal size){_relativeSize = size;}
	  void set_FretFont(QFont font) { _FretFont = font; }

      qreal get_relativeSize() {return _relativeSize;}
      QRectF bbox(QFont font, QPointF pos, QString string);
      QString shapString() {return "♯";}
      QString flatString() {return "♭";}
	  QFont getFretFont() const { return _FretFont; }


      void drawShap(QPainter* painter, QPointF pos, QFont font) const;
      void drawFlat(QPainter* painter, QPointF pos, QFont font) const;
      };
}
#endif // CIPHER_H
