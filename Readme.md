cd verilog && make clk_test  # 验证时钟系统
python3 python/fpga_tester.py --mode=continuous --duration=60 --pattern=AA55  # 运行完整测试