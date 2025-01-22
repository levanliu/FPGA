"""
FPGA芯片测试控制程序
版本: 1.2
功能: 通过UART协议控制FPGA测试系统，支持自动测试、结果分析和报告生成
"""

import serial
import time
import struct
import matplotlib.pyplot as plt
from enum import IntEnum

class TestMode(IntEnum):
    SINGLE = 0x00      # 单次测试模式
    CONTINUOUS = 0x01  # 连续测试模式
    STRESS = 0x02      # 压力测试模式

class FPGATester:
    def __init__(self, port='/dev/ttyUSB0', baudrate=115200):
        self.ser = serial.Serial(port, baudrate, timeout=1)
        self.test_results = []
        
        # 协议常量
        self.START_BYTE = 0xAA
        self.ACK_BYTE = 0x55
        self.CRC_POLY = 0xEDB88320
        
        # 状态寄存器
        self._error_count = 0
        self._test_done = False

    def _send_command(self, cmd_type, data=None):
        """发送测试命令到FPGA"""
        frame = bytearray()
        frame.append(self.START_BYTE)
        frame.append(cmd_type)
        
        if data:
            if isinstance(data, int):
                data = data.to_bytes(4, 'little')
            frame.extend(len(data).to_bytes(2, 'big'))
            frame.extend(data)
            frame.extend(self._calculate_crc32(frame[1:]))
        
        self.ser.write(frame)
        
        # 等待确认
        ack = self.ser.read(1)
        if ack != self.ACK_BYTE:
            raise IOError("FPGA未响应命令")

    def _calculate_crc32(self, data):
        """计算CRC32校验值"""
        crc = 0xFFFFFFFF
        for byte in data:
            crc ^= byte
            for _ in range(8):
                crc = (crc >> 1) ^ (self.CRC_POLY & -(crc & 1))
        return (crc ^ 0xFFFFFFFF).to_bytes(4, 'little')

    def configure_test(self, test_mode, max_cycles=1000, pattern=0xAAAA):
        """
        配置测试参数
        :param test_mode: 测试模式 (TestMode枚举值)
        :param max_cycles: 最大测试循环次数（连续模式有效）
        :param pattern: 测试模式数据（16位）
        """
        config_data = bytearray()
        config_data.append(test_mode)
        config_data.extend(max_cycles.to_bytes(4, 'little'))
        config_data.extend(pattern.to_bytes(2, 'little'))
        config_data.append(0x00)  # 填充字节
        
        self._send_command(0x01, config_data)

    def start_test(self):
        """启动测试"""
        self._send_command(0x02)
        self._monitor_test_status()

    def _monitor_test_status(self):
        """监控测试状态"""
        start_time = time.time()
        while True:
            # 读取状态寄存器（示例地址）
            self.ser.write(bytearray([0x03]))
            status = self.ser.read(4)
            
            if len(status) == 4:
                self._error_count = int.from_bytes(status[:2], 'little')
                self._test_done = bool(status[2] & 0x01)
                
                # 更新测试结果
                self.test_results.append({
                    'timestamp': time.time() - start_time,
                    'errors': self._error_count
                })
                
                if self._test_done:
                    break
            
            time.sleep(0.1)

    def generate_report(self, show_trend=True, save_html=False):
        """生成增强版测试报告
        :param show_trend: 是否显示错误趋势图
        :param save_html: 是否生成HTML报告
        """
        if not self.test_results:
            print("没有可用的测试数据")
            return
        
        total_errors = self.test_results[-1]['errors']
        duration = self.test_results[-1]['timestamp']
        max_errors = max(r['errors'] for r in self.test_results)
        error_rate = total_errors / duration if duration else 0

        # 生成文本报告
        report = f"""FPGA增强测试报告
        ========================
        测试时间: {time.ctime()}
        总持续时间: {duration:.2f} 秒
        总错误数: {total_errors}
        峰值错误数: {max_errors}
        平均错误率: {error_rate:.2f} 错误/秒
        最大持续无错误时间: {self._calculate_max_error_free_interval():.2f} 秒
        """
        with open('test_report.txt', 'w') as f:
            f.write(report)

        # 生成趋势图
        if show_trend:
            timestamps = [r['timestamp'] for r in self.test_results]
            errors = [r['errors'] for r in self.test_results]
            
            plt.figure(figsize=(12, 6))
            plt.plot(timestamps, errors, 'r-', label='错误计数')
            plt.fill_between(timestamps, errors, alpha=0.2)
            plt.title('FPGA测试错误趋势分析')
            plt.xlabel('时间 (秒)')
            plt.ylabel('错误计数')
            plt.grid(True)
            plt.legend()
            plt.savefig('test_report.png', dpi=300)
            plt.close()

        # 生成HTML报告
        if save_html:
            html_content = f"""
            <html>
            <head><title>FPGA测试报告</title></head>
            <body>
                <h1>FPGA测试报告 - {time.ctime()}</h1>
                <div id="stats">
                    <h2>测试统计</h2>
                    <p>持续时间: {duration:.2f}s</p>
                    <p>总错误数: {total_errors}</p>
                    <p>峰值错误数: {max_errors}</p>
                    <p>平均错误率: {error_rate:.2f}/s</p>
                </div>
                <div id="chart">
                    <h2>错误趋势图</h2>
                    <img src="test_report.png" width="800">
                </div>
            </body>
            </html>
            """
            with open('test_report.html', 'w') as f:
                f.write(html_content)

        print("测试报告已生成: test_report.txt, test_report.png" + 
              (" 和 test_report.html" if save_html else ""))

    def _calculate_max_error_free_interval(self):
        """计算最大无错误间隔"""
        max_interval = 0
        current_interval = 0
        prev_time = self.test_results[0]['timestamp']
        
        for result in self.test_results[1:]:
            dt = result['timestamp'] - prev_time
            if result['errors'] == 0:
                current_interval += dt
                if current_interval > max_interval:
                    max_interval = current_interval
            else:
                current_interval = 0
            prev_time = result['timestamp']
        return max_interval

    def run_full_test(self, test_mode=TestMode.CONTINUOUS, duration=60, pattern=0xAA55):
        """执行完整测试流程
        :param test_mode: 测试模式 (TestMode枚举值)
        :param duration: 测试持续时间（秒）
        :param pattern: 测试模式数据（16位）
        """
        try:
            print(f"正在配置测试参数[模式: {test_mode.name}, 时长: {duration}s, 模式: 0x{pattern:04X}]...")
            self.configure_test(test_mode, max_cycles=int(1e6), pattern=pattern)
            
            print("启动测试...")
            start_time = time.time()
            while time.time() - start_time < duration:
                self.start_test()
                self._monitor_test_status()
            
            print("生成增强版测试报告...")
            self.generate_report(show_trend=True, save_html=True)
            
        except Exception as e:
            print(f"测试失败: {str(e)}")
        finally:
            self.ser.close()

if __name__ == "__main__":
    tester = FPGATester()
    tester.run_full_test(TestMode.CONTINUOUS)
