# FPGA测试系统构建文件
IVERILOG = iverilog
VVP = vvp
TARGET = fpgatest

# 时钟测试相关文件
CLK_TEST_SRC = \
	Clock_Manager.v \
	TestSystem_Top.v \
	CDC_Sync.v \
	Test_FSM.v \
	ConfigParser.v \
	DigitalIO_Ctrl.v \
	ADC_Interface.v \
	DAC_Interface.v \
	Result_Analyzer.v \
	Data_Buffer.v \
	Protocol_Adapter.v \
	Power_Manager.v \
	TestPattern_Standard.v

all: $(TARGET)

$(TARGET): $(CLK_TEST_SRC)
	$(IVERILOG) -o $@ $^

clk_test: $(TARGET)
	$(VVP) $(TARGET) +TESTCASE=CLOCK_TEST

sim: $(TARGET)
	$(VVP) $(TARGET) +TESTCASE=FULL_TEST

clean:
	rm -f $(TARGET) *.vcd

.PHONY: all clean clk_test sim
