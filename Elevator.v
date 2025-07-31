//======================== Elevator FSM Controller ========================
module elevator_fsm (
    input clk,
    input reset,
    input [1:0] floor_request,
    input request_valid,
    input emergency,
    input alarm_btn,
    output reg [1:0] current_floor,
    output reg moving,
    output reg door_open,
    output reg alarm,
    output reg emergency_call
);

    parameter IDLE = 3'b000,
              MOVING = 3'b001,
              DOOR_OPEN = 3'b010,
              ALARM = 3'b011,
              EMERGENCY = 3'b100;

    reg [2:0] state, next_state;
    reg [1:0] target_floor;
    reg [3:0] door_timer;
    reg [3:0] floor_queue;
    reg [1:0] request_fifo [3:0]; 
    integer head = 0, tail = 0;

    // FSM Sequential
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            current_floor <= 2'b00;
            alarm <= 0;
            emergency_call <= 0;
            door_timer <= 0;
            floor_queue <= 0;
            head <= 0;
            tail <= 0;
        end else begin
            state <= next_state;

            if (state == DOOR_OPEN) begin
                if (door_timer < 4'd10)
                    door_timer <= door_timer + 1;
            end else begin
                door_timer <= 0;
            end

            if (request_valid && !floor_queue[floor_request]) begin
                floor_queue[floor_request] <= 1;
                request_fifo[tail] <= floor_request;
                tail <= (tail + 1) % 4;
            end

            if (state == DOOR_OPEN && floor_queue[current_floor]) begin
                floor_queue[current_floor] <= 0;
                if (head != tail) head <= (head + 1) % 4;
            end

            if (state == MOVING) begin
                if (current_floor < target_floor)
                    current_floor <= current_floor + 1;
                else if (current_floor > target_floor)
                    current_floor <= current_floor - 1;
            end
        end
    end

    // FSM Combinational
    always @(*) begin
        next_state = state;
        moving = 0;
        door_open = 0;
        alarm = 0;
        emergency_call = 0;
        target_floor = request_fifo[head];

        case (state)
            IDLE: begin
                if (emergency)
                    next_state = EMERGENCY;
                else if (alarm_btn)
                    next_state = ALARM;
                else if (floor_queue != 4'b0000 && current_floor != target_floor)
                    next_state = MOVING;
                else if (floor_queue[current_floor])
                    next_state = DOOR_OPEN;
            end

            MOVING: begin
                moving = 1;
                if (current_floor == target_floor)
                    next_state = DOOR_OPEN;
            end

            DOOR_OPEN: begin
                door_open = 1;
                if (door_timer >= 4'd10)
                    next_state = IDLE;
            end

            ALARM: begin
                alarm = 1;
                next_state = IDLE;
            end

            EMERGENCY: begin
                emergency_call = 1;
                next_state = IDLE;
            end
        endcase
    end
endmodule
