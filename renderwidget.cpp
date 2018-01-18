#include "renderwidget.h"

RenderWidget::RenderWidget(QWidget *parent)
    : QWidget(parent)
{
    SimulatorFileObject *fileObject = SimulatorObjectFactory::GetInstance().CreateFileObject("auv_renderer.frag");
    qDebug() << fileObject->Stringify();
}

RenderWidget::~RenderWidget()
{

}
