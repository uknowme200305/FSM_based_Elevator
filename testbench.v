//======================== Elevator FSM Testbench ========================
module tb_elevator_fsm;
    reg clk, reset, request_valid, emergency, alarm_btn;
    reg [1:0] floor_request;
    wire [1:0] current_floor;
    wire moving, door_open, alarm, emergency_call;

    elevator_fsm dut (
        .clk(clk),
        .reset(reset),
        .floor_request(floor_request),
        .request_valid(request_valid),
        .emergency(emergency),
        .alarm_btn(alarm_btn),
        .current_floor(current_floor),
        .moving(moving),
        .door_open(door_open),
        .alarm(alarm),
        .emergency_call(emergency_call)
    );

  
    initial clk = 0;
    always #5 clk = ~clk; 

    task send_request(input [1:0] floor);
        begin
            floor_request = floor;
            request_valid = 1; #10;
            request_valid = 0; #10;
        end
    endtask

    initial begin
        $dumpfile("elevator_tb.vcd");
        $dumpvars(0, tb_elevator_fsm);

        // Initialize
        reset = 1;
        request_valid = 0;
        floor_request = 2'b00;
        emergency = 0;
        alarm_btn = 0;
        #10 reset = 0;

        // Sequential floor requests from IDLE state
        send_request(2);
        send_request(1);
        send_request(3);
        #300;

        // Emergency during motion
        send_request(0);
        #30 emergency = 1; #10 emergency = 0;
        #200;

        //  Alarm triggered
        #10 alarm_btn = 1; #10 alarm_btn = 0;
        #100;

        //  Multiple requests while elevator is moving
        send_request(3);
        #20 send_request(1);
        #150;

        //  request for current floor
        #20 send_request(current_floor);
        #100;

        //  Request to all floors quickly
        send_request(0);
        send_request(1);
        send_request(2);
        send_request(3);
        #500;

        $finish;
    end
endmodule
