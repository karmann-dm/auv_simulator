#include "renderwidget.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    RenderWidget w;
    w.show();

    return a.exec();
}
