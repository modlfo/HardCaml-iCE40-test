
module test;
    reg clk;
    reg reset;
    wire led;
    wire dac_clk;
    wire [7:0]dac;

    top t (
        .BUT1(reset),
        .CLK(clk),
        .LED1(led),
        .DAC_CLK(dac_clk),
        .DAC(dac)
    );

    initial begin
        clk = 0;
        reset = 0;
        # 1 reset = 1;
    end

    always
        #1  clk =  ! clk;

    initial
        #200000  $finish;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars;
    end
endmodule