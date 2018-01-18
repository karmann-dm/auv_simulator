#ifndef RENDERWIDGET_H
#define RENDERWIDGET_H

#include <QWidget>
#include <QDebug>
#include "simulator/base/simulatorobjectfactory.h"

class RenderWidget : public QWidget
{
    Q_OBJECT
public:
    RenderWidget(QWidget *parent = 0);
    ~RenderWidget();
};

#endif // RENDERWIDGET_H
