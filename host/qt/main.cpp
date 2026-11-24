#include <QApplication>
#include <QComboBox>
#include <QDateTime>
#include <QGridLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPainter>
#include <QPushButton>
#include <QRegularExpression>
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QTextEdit>
#include <QTimer>
#include <QVBoxLayout>
#include <QVector>
#include <QWidget>

#include <cmath>

struct Telemetry {
    quint64 words = 0;
    quint64 errors = 0;
    quint64 cycles = 0;
    quint64 bits = 0;
    quint64 highWater = 0;
    quint64 fullCycles = 0;
    quint64 emptyCycles = 0;
    quint64 writes = 0;
    quint64 reads = 0;
    quint64 producerStalls = 0;
    quint64 consumerStalls = 0;
    quint64 overflows = 0;
    quint64 underflows = 0;
    bool running = false;
    double throughputBps = 0.0;
    double wordErrorRate = 0.0;
    double bitErrorRate = 0.0;
};

class ThroughputPlot final : public QWidget {
public:
    explicit ThroughputPlot(QWidget *parent = nullptr) : QWidget(parent) {
        setMinimumHeight(180);
    }

    void append(double value) {
        m_values.append(value);
        while (m_values.size() > 120)
            m_values.removeFirst();
        update();
    }

protected:
    void paintEvent(QPaintEvent *) override {
        QPainter painter(this);
        painter.fillRect(rect(), QColor("#101820"));
        painter.setRenderHint(QPainter::Antialiasing);
        painter.setPen(QColor("#607080"));
        painter.drawRect(8, 8, width() - 16, height() - 16);

        if (m_values.isEmpty())
            return;

        double maximum = 1.0;
        for (double value : m_values)
            maximum = std::max(maximum, value);

        QPolygonF polyline;
        const double plotWidth = width() - 24.0;
        const double plotHeight = height() - 24.0;
        for (int i = 0; i < m_values.size(); ++i) {
            const double x = 12.0 + plotWidth * i /
                std::max<qsizetype>(1, m_values.size() - 1);
            const double y = height() - 12.0 - plotHeight * m_values[i] / maximum;
            polyline.append(QPointF(x, y));
        }
        painter.setPen(QPen(QColor("#44d7b6"), 2));
        painter.drawPolyline(polyline);
    }

private:
    QVector<double> m_values;
};

class MainWindow final : public QWidget {
    Q_OBJECT

public:
    MainWindow() {
        setWindowTitle("Basys 3 Streaming Monitor");
        resize(900, 650);

        auto *root = new QVBoxLayout(this);
        auto *controls = new QHBoxLayout;
        m_ports = new QComboBox;
        m_refresh = new QPushButton("Refresh ports");
        m_connect = new QPushButton("Connect");
        controls->addWidget(new QLabel("UART:"));
        controls->addWidget(m_ports, 1);
        controls->addWidget(m_refresh);
        controls->addWidget(m_connect);
        root->addLayout(controls);

        auto *grid = new QGridLayout;
        addMetric(grid, 0, 0, "State", m_state);
        addMetric(grid, 0, 1, "Words checked", m_words);
        addMetric(grid, 0, 2, "Word errors", m_errors);
        addMetric(grid, 1, 0, "Throughput", m_throughput);
        addMetric(grid, 1, 1, "Bit errors", m_bits);
        addMetric(grid, 1, 2, "Word error rate", m_wordRate);
        addMetric(grid, 2, 0, "FIFO high-water", m_highWater);
        addMetric(grid, 2, 1, "Full cycles", m_fullCycles);
        addMetric(grid, 2, 2, "Empty cycles", m_emptyCycles);
        addMetric(grid, 3, 0, "Accepted writes", m_writes);
        addMetric(grid, 3, 1, "Accepted reads", m_reads);
        addMetric(grid, 3, 2, "Producer stalls", m_producerStalls);
        addMetric(grid, 4, 0, "Consumer stalls", m_consumerStalls);
        addMetric(grid, 4, 1, "Overflow attempts", m_overflows);
        addMetric(grid, 4, 2, "Underflow attempts", m_underflows);
        root->addLayout(grid);

        root->addWidget(new QLabel("Throughput history (bits/second)"));
        m_plot = new ThroughputPlot;
        root->addWidget(m_plot);
        m_log = new QTextEdit;
        m_log->setReadOnly(true);
        root->addWidget(m_log, 1);

        m_serial.setBaudRate(QSerialPort::Baud115200);
        connect(m_refresh, &QPushButton::clicked, this, &MainWindow::refreshPorts);
        connect(m_connect, &QPushButton::clicked, this, &MainWindow::toggleConnection);
        connect(&m_serial, &QSerialPort::readyRead, this, &MainWindow::readSerial);
        refreshPorts();
    }

private slots:
    void refreshPorts() {
        const QString current = m_ports->currentText();
        m_ports->clear();
        for (const QSerialPortInfo &info : QSerialPortInfo::availablePorts())
            m_ports->addItem(info.portName(), info.systemLocation());
        const int index = m_ports->findText(current);
        if (index >= 0)
            m_ports->setCurrentIndex(index);
    }

    void toggleConnection() {
        if (m_serial.isOpen()) {
            m_serial.close();
            m_connect->setText("Connect");
            m_state->setText("Disconnected");
            return;
        }
        m_serial.setPortName(m_ports->currentData().toString());
        if (m_serial.open(QIODevice::ReadOnly)) {
            m_connect->setText("Disconnect");
            m_state->setText("Connected");
            m_log->append("Connected to " + m_serial.portName());
        } else {
            m_log->append("UART open error: " + m_serial.errorString());
        }
    }

    void readSerial() {
        m_buffer += m_serial.readAll();
        while (true) {
            const int newline = m_buffer.indexOf('\n');
            if (newline < 0)
                break;
            const QByteArray line = m_buffer.left(newline).trimmed();
            m_buffer.remove(0, newline + 1);
            parseLine(QString::fromLatin1(line));
        }
    }

private:
    static void addMetric(QGridLayout *grid, int row, int column,
                          const QString &title, QLabel *&value) {
        auto *box = new QVBoxLayout;
        box->addWidget(new QLabel(title));
        value = new QLabel("-");
        value->setStyleSheet("font-size: 18px; font-weight: bold;");
        box->addWidget(value);
        grid->addLayout(box, row, column);
    }

    static bool parseHex(const QString &text, quint64 &value) {
        bool ok = false;
        value = text.toULongLong(&ok, 16);
        return ok;
    }

    void parseLine(const QString &line) {
        static const QRegularExpression expression(
            R"(^STAT W=([0-9A-Fa-f]{16}) E=([0-9A-Fa-f]{16}) C=([0-9A-Fa-f]{16}) B=([0-9A-Fa-f]{16}) H=([0-9A-Fa-f]{4}) F=([0-9A-Fa-f]{16}) M=([0-9A-Fa-f]{16}) R=([01]) I=([0-9A-Fa-f]{16}) O=([0-9A-Fa-f]{16}) P=([0-9A-Fa-f]{16}) Q=([0-9A-Fa-f]{16}) X=([0-9A-Fa-f]{16}) Y=([0-9A-Fa-f]{16})$)");
        const QRegularExpressionMatch match = expression.match(line);
        if (!match.hasMatch())
            return;

        Telemetry telemetry;
        quint64 *values[] = {
            &telemetry.words, &telemetry.errors, &telemetry.cycles,
            &telemetry.bits, &telemetry.highWater, &telemetry.fullCycles,
            &telemetry.emptyCycles, &telemetry.writes, &telemetry.reads,
            &telemetry.producerStalls, &telemetry.consumerStalls,
            &telemetry.overflows, &telemetry.underflows
        };
        for (int i = 0; i < 13; ++i) {
            if (!parseHex(match.captured(i + 1), *values[i]))
                return;
        }
        telemetry.running = match.captured(8) == "1";
        const long double totalBits = static_cast<long double>(telemetry.words) * 128.0L;
        telemetry.throughputBps = telemetry.cycles
            ? static_cast<double>(totalBits * 100000000.0L / telemetry.cycles)
            : 0.0;
        telemetry.wordErrorRate = telemetry.words
            ? static_cast<double>(telemetry.errors) / telemetry.words : 0.0;
        telemetry.bitErrorRate = totalBits
            ? static_cast<double>(telemetry.bits) / static_cast<double>(totalBits) : 0.0;

        m_state->setText(telemetry.running ? "Running" : "Stopped");
        m_words->setText(QString::number(telemetry.words));
        m_errors->setText(QString::number(telemetry.errors));
        m_throughput->setText(QString::number(telemetry.throughputBps, 'f', 0) + " b/s");
        m_bits->setText(QString::number(telemetry.bits));
        m_wordRate->setText(QString::number(telemetry.wordErrorRate, 'g', 5));
        m_highWater->setText(QString::number(telemetry.highWater));
        m_fullCycles->setText(QString::number(telemetry.fullCycles));
        m_emptyCycles->setText(QString::number(telemetry.emptyCycles));
        m_writes->setText(QString::number(telemetry.writes));
        m_reads->setText(QString::number(telemetry.reads));
        m_producerStalls->setText(QString::number(telemetry.producerStalls));
        m_consumerStalls->setText(QString::number(telemetry.consumerStalls));
        m_overflows->setText(QString::number(telemetry.overflows));
        m_underflows->setText(QString::number(telemetry.underflows));
        m_plot->append(telemetry.throughputBps);
        m_log->append(QDateTime::currentDateTime().toString(Qt::ISODate) + " " + line);
    }

    QComboBox *m_ports = nullptr;
    QPushButton *m_refresh = nullptr;
    QPushButton *m_connect = nullptr;
    QSerialPort m_serial;
    QByteArray m_buffer;
    QLabel *m_state = nullptr;
    QLabel *m_words = nullptr;
    QLabel *m_errors = nullptr;
    QLabel *m_throughput = nullptr;
    QLabel *m_bits = nullptr;
    QLabel *m_wordRate = nullptr;
    QLabel *m_highWater = nullptr;
    QLabel *m_fullCycles = nullptr;
    QLabel *m_emptyCycles = nullptr;
    QLabel *m_writes = nullptr;
    QLabel *m_reads = nullptr;
    QLabel *m_producerStalls = nullptr;
    QLabel *m_consumerStalls = nullptr;
    QLabel *m_overflows = nullptr;
    QLabel *m_underflows = nullptr;
    ThroughputPlot *m_plot = nullptr;
    QTextEdit *m_log = nullptr;
};

#include "main.moc"

int main(int argc, char **argv) {
    QApplication application(argc, argv);
    MainWindow window;
    window.show();
    return application.exec();
}
