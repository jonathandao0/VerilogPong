// Listing 13.5
module pong_graph_animate
   (
    input wire clk, reset,
    input wire video_on,
    input wire [1:0] btn,
    input wire [9:0] pix_x, pix_y,
    output reg [11:0] graph_rgb,
    output reg ctest
   );

   // constant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   wire refr_tick;
   //--------------------------------------------
   // vertical stripe as a wall
   //--------------------------------------------
   // wall left, right boundary
   localparam WALL_Y_T = 32;
   localparam WALL_Y_B = 35;
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // bar left, right boundary
   localparam BAR_Y_T = 440;
   localparam BAR_Y_B = 443;
   // bar top, bottom boundary
   wire [9:0] bar_x_l, bar_x_r;
   localparam BAR_X_SIZE = 100;
   // register to track top boundary  (x position is fixed)
   reg [9:0] bar_x_reg, bar_x_next;
   // bar moving velocity when a button is pressed
   localparam BAR_V = 4;
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 16;
   // ball left, right boundary
   wire [9:0] ball_x_l, ball_x_r;
   // ball top, bottom boundary
   wire [9:0] ball_y_t, ball_y_b;
   // reg to track left, top position
   reg [9:0] ball_x_reg, ball_y_reg;
   wire [9:0] ball_x_next, ball_y_next;
   // reg to track ball speed
   reg [9:0] x_delta_reg, x_delta_next;
   reg [9:0] y_delta_reg, y_delta_next;
   // ball velocity can be pos or neg)
   localparam BALL_V_P = 2;
   localparam BALL_V_N = -2;
   //--------------------------------------------
   // round ball
   //--------------------------------------------
   wire [2:0] rom_addr, rom_col;
   reg [7:0] rom_data;
   wire rom_bit;
   
   //custom ball
   localparam BALL_RADIUS = 8;                       
   localparam N_RADIUS = 4;                          
   // ball left, right boundary                      
   localparam BALL_X_L = 576;                        
   localparam BALL_X_R = BALL_X_L + (BALL_RADIUS * 2);
   // ball top, bottom boundary                      
   localparam BALL_Y_T = 234;                        
   localparam BALL_Y_B = BALL_Y_T + (BALL_RADIUS * 2);
   // Sphere params                                  
   wire[9:0] BALL_CENTER_X;
   wire[9:0] BALL_CENTER_Y;
   
   // Counter
   reg[3:0] counter1;
   reg[3:0] counter2;
   reg ctest;
   reg count;
   
   initial counter1 = 0;
   initial counter2 = 0;
   initial ctest = 0;
   initial count = 0;
      
   assign counter_rgb = 12'b1111_1111_1111;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire wall_on, bar_on, sq_ball_on, rd_ball_on;
   wire [11:0] wall_rgb, bar_rgb, ball_rgb;

   // body
   //--------------------------------------------
   // round ball image ROM
   //--------------------------------------------
   always @*
   case (rom_addr)
      3'h0: rom_data = 8'b00111100; //   ****
      3'h1: rom_data = 8'b01111110; //  ******
      3'h2: rom_data = 8'b11111111; // ********
      3'h3: rom_data = 8'b11111111; // ********
      3'h4: rom_data = 8'b11111111; // ********
      3'h5: rom_data = 8'b11111111; // ********
      3'h6: rom_data = 8'b01111110; //  ******
      3'h7: rom_data = 8'b00111100; //   ****
   endcase

   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            bar_x_reg <= 0;
            ball_x_reg <= 0;
            ball_y_reg <= 0;
            x_delta_reg <= 10'h004;
            y_delta_reg <= 10'h004;
         end
      else
         begin
            bar_x_reg <= bar_x_next;
            ball_x_reg <= ball_x_next;
            ball_y_reg <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
         end

   // refr_tick: 1-clock tick asserted at start of v-sync
   //            i.e., when the screen is refreshed (60 Hz)
   assign refr_tick = (pix_y==481) && (pix_x==0);

   //--------------------------------------------
   // (wall) left vertical strip
   //--------------------------------------------
   // pixel within wall
   assign wall_on = (WALL_Y_T<=pix_y) && (pix_y<=WALL_Y_B);
   // wall rgb output
   assign wall_rgb = 12'b0000_0000_1111; // blue
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // boundary
   assign bar_x_l = bar_x_reg;
   assign bar_x_r = bar_x_l + BAR_X_SIZE - 1;
   // pixel within bar
   assign bar_on = (BAR_Y_T<=pix_y) && (pix_y<=BAR_Y_B) &&
                   (bar_x_l<=pix_x) && (pix_x<=bar_x_r);
   // bar rgb output
   assign bar_rgb = 12'b0000_1111_0000; // green
   // new bar y-position
   always @*
   begin
      bar_x_next = bar_x_reg; // no move
      if (refr_tick)
         if (btn[1] & (bar_x_r < (MAX_X-1-BAR_V)))
            bar_x_next = bar_x_reg + BAR_V; // move down
         else if (btn[0] & (bar_x_l > BAR_V))
            bar_x_next = bar_x_reg - BAR_V; // move up
   end

   //--------------------------------------------
   // square ball
   //--------------------------------------------
   // boundary
   assign ball_x_l = ball_x_reg;
   assign ball_y_t = ball_y_reg;
   assign ball_x_r = ball_x_l + BALL_SIZE;
   assign ball_y_b = ball_y_t + BALL_SIZE;
   assign BALL_CENTER_X = ball_x_l + BALL_RADIUS;
   assign BALL_CENTER_Y = ball_y_t + BALL_RADIUS;
   // pixel within ball
   assign sq_ball_on = (ball_x_l<=pix_x) && (pix_x<=ball_x_r) &&
                        (ball_y_t<=pix_y) && (pix_y<=ball_y_b);
   // circle
   assign limit1 = (((BALL_CENTER_X-pix_x) * (BALL_CENTER_X-pix_x)) + 
                    ((BALL_CENTER_Y-pix_y) * (BALL_CENTER_Y-pix_y))) <= 
                   (BALL_RADIUS * BALL_RADIUS); // x^2+y^2=r^2; 
   // negate circle
   assign limit2 = ~((((BALL_CENTER_X-pix_x) * (BALL_CENTER_X-pix_x)) + 
                       ((BALL_CENTER_Y-pix_y) * (BALL_CENTER_Y-pix_y))) <= 
                     (N_RADIUS * N_RADIUS)); // x^2+y^2=r^2;                
   
   assign custom_on = sq_ball_on & limit1 & limit2;       
            
   // map current pixel location to ROM addr/col
   assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
   assign rom_col = pix_x[2:0] - ball_x_l[2:0];
   assign rom_bit = rom_data[rom_col];
   // pixel within ball
   assign rd_ball_on = sq_ball_on & rom_bit;
   // ball rgb output
   assign ball_rgb = 12'b1111_0000_0000;   // red
   // new ball position
   assign ball_x_next = (refr_tick) ? ball_x_reg+x_delta_reg :
                        ball_x_reg ;
   assign ball_y_next = (refr_tick) ? ball_y_reg+y_delta_reg :
                        ball_y_reg ;
   // new ball velocity
   always @*
   begin
      x_delta_next = x_delta_reg;
      y_delta_next = y_delta_reg;
      if (ball_x_l < 1) // reach left
         x_delta_next = BALL_V_P;
      else if (ball_x_r > (MAX_X-1)) // reach right
         x_delta_next = BALL_V_N;
      else if (ball_y_t <= WALL_Y_B) // reach wall (top)
         y_delta_next = BALL_V_P;    // bounce back
      else if ((BAR_Y_T<=ball_y_b) && (ball_y_b<=BAR_Y_B) &&
               (bar_x_l<=ball_x_r) && (ball_x_l<=bar_x_r))
         // reach x of right bar and hit, ball bounce back (bottom)
         y_delta_next = BALL_V_N;
   end
   
   //counter
   // counter logic
   
   always @(posedge clk)
   begin
        if(ball_y_t == MAX_Y)
            ctest = ~ctest;
        if((ball_y_b == MAX_Y) && (counter2 == 9) && (counter1 == 9) && (count == 0)) 
        begin
            counter1 = 0;
            counter2 = 0;
            count = 1;
        end
        else if((ball_y_b == MAX_Y) && (counter1 == 9) && (count == 0)) begin
            counter1 = 0;
            counter2 = counter2 + 1;
            count = 1;
        end
        else if((ball_y_b == MAX_Y) && (counter1 < 9) && (count == 0)) begin
            counter1 = counter1 + 1;
            count = 1;
        end
        else if (ball_y_b != MAX_Y)
            count = 0;
    end
    
    // counter display logic
    wire[12:0]c1pix, c2pix;
    assign c1pix[00] = ((20 <= pix_x) && (pix_x <= 21) && ( 4 <= pix_y) && (pix_y <=  5)) && ~(counter1 == 1);                                                                              
    assign c1pix[01] = ((22 <= pix_x) && (pix_x <= 23) && ( 4 <= pix_y) && (pix_y <=  5)) && ~((counter1 == 1) || (counter1 == 4));                                                         
    assign c1pix[02] = ((24 <= pix_x) && (pix_x <= 25) && ( 4 <= pix_y) && (pix_y <=  5));                                                                                                 
                      
    assign c1pix[03] = ((20 <= pix_x) && (pix_x <= 21) && ( 6 <= pix_y) && (pix_y <=  7)) && ~((counter1 == 1) || (counter1 == 2) || (counter1 == 3) || (counter1 == 7));                   
    assign c1pix[04] = ((24 <= pix_x) && (pix_x <= 25) && ( 6 <= pix_y) && (pix_y <=  7)) && ~((counter1 == 5) || (counter1 == 6));                                                                              
                 
    assign c1pix[05] = ((20 <= pix_x) && (pix_x <= 21) && ( 8 <= pix_y) && (pix_y <=  9)) && ~((counter1 == 1) || (counter1 == 7));                                                         
    assign c1pix[06] = ((22 <= pix_x) && (pix_x <= 23) && ( 8 <= pix_y) && (pix_y <=  9)) && ~((counter1 == 0) || (counter1 == 1) || (counter1 == 7));                                      
    assign c1pix[07] = ((24 <= pix_x) && (pix_x <= 25) && ( 8 <= pix_y) && (pix_y <=  9));                                                                                                 
                       
    assign c1pix[08] = ((20 <= pix_x) && (pix_x <= 21) && (10 <= pix_y) && (pix_y <= 11)) && ~((counter1 == 1) || (counter1 == 3) || (counter1 == 4) || (counter1 == 5) || (counter1 == 7) || (counter1 == 9));
    assign c1pix[09] = ((24 <= pix_x) && (pix_x <= 25) && (10 <= pix_y) && (pix_y <= 11)) && ~(counter1 == 2);                                                                              
                      
    assign c1pix[10] = ((20 <= pix_x) && (pix_x <= 21) && (12 <= pix_y) && (pix_y <= 13)) && ~((counter1 == 1) || (counter1 == 4) || (counter1 == 7));                                      
    assign c1pix[11] = ((22 <= pix_x) && (pix_x <= 23) && (12 <= pix_y) && (pix_y <= 13)) && ~((counter1 == 1) || (counter1 == 4) || (counter1 == 7));                                      
    assign c1pix[12] = ((24 <= pix_x) && (pix_x <= 25) && (12 <= pix_y) && (pix_y <= 13));
                    
                    
    assign c2pix[00] = ((12 <= pix_x) && (pix_x <= 13) && ( 4 <= pix_y) && (pix_y <=  5)) && ~(counter2 == 1);
    assign c2pix[01] = ((14 <= pix_x) && (pix_x <= 15) && ( 4 <= pix_y) && (pix_y <=  5)) && ~((counter2 == 1) || (counter2 == 4));
    assign c2pix[02] = ((16 <= pix_x) && (pix_x <= 17) && ( 4 <= pix_y) && (pix_y <=  5));
                       
    assign c2pix[03] = ((12 <= pix_x) && (pix_x <= 13) && ( 6 <= pix_y) && (pix_y <=  7)) && ~((counter2 == 1) || (counter2 == 2) || (counter2 == 3) || (counter2 == 7));
    assign c2pix[04] = ((16 <= pix_x) && (pix_x <= 17) && ( 6 <= pix_y) && (pix_y <=  7)) && ~((counter2 == 5) || (counter2 == 6));       
                  
    assign c2pix[05] = ((12 <= pix_x) && (pix_x <= 13) && ( 8 <= pix_y) && (pix_y <=  9)) && ~((counter2 == 1) || (counter2 == 7));
    assign c2pix[06] = ((14 <= pix_x) && (pix_x <= 15) && ( 8 <= pix_y) && (pix_y <=  9)) && ~((counter2 == 0) || (counter2 == 1) || (counter2 == 7));
    assign c2pix[07] = ((16 <= pix_x) && (pix_x <= 17) && ( 8 <= pix_y) && (pix_y <=  9));
                       
    assign c2pix[08] = ((12 <= pix_x) && (pix_x <= 13) && (10 <= pix_y) && (pix_y <= 11)) && ~((counter2 == 1) || (counter2 == 3) || (counter2 == 4) || (counter2 == 5) || (counter2 == 7) || (counter2 == 9));
    assign c2pix[09] = ((16 <= pix_x) && (pix_x <= 17) && (10 <= pix_y) && (pix_y <= 11)) && ~(counter2 == 2);
                                                                                       
    assign c2pix[10] = ((12 <= pix_x) && (pix_x <= 13) && (12 <= pix_y) && (pix_y <= 13)) && ~((counter2 == 1) || (counter2 == 4) || (counter2 == 7));
    assign c2pix[11] = ((14 <= pix_x) && (pix_x <= 15) && (12 <= pix_y) && (pix_y <= 13)) && ~((counter2 == 1) || (counter2 == 4) || (counter2 == 7));
    assign c2pix[12] = ((16 <= pix_x) && (pix_x <= 17) && (12 <= pix_y) && (pix_y <= 13));
    
    assign tpix = ((8 <= pix_x) && (pix_x <= 9) && (8 <= pix_y) && (pix_y <= 9)) && ctest;
    
    //assign counter1_on = |c1pix;
    //assign counter2_on = |c2pix;
   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 12'b0000_0000_0000; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (bar_on)
            graph_rgb = bar_rgb;
         else if (custom_on)
            graph_rgb = ball_rgb;
         else if(c1pix[00]) graph_rgb = counter_rgb;
         else if(c1pix[01]) graph_rgb = counter_rgb;
         else if(c1pix[02]) graph_rgb = counter_rgb;
         else if(c1pix[03]) graph_rgb = counter_rgb;
         else if(c1pix[04]) graph_rgb = counter_rgb;
         else if(c1pix[05]) graph_rgb = counter_rgb;
         else if(c1pix[06]) graph_rgb = counter_rgb;
         else if(c1pix[07]) graph_rgb = counter_rgb;
         else if(c1pix[08]) graph_rgb = counter_rgb;
         else if(c1pix[09]) graph_rgb = counter_rgb;
         else if(c1pix[10]) graph_rgb = counter_rgb;
         else if(c1pix[11]) graph_rgb = counter_rgb;
         else if(c1pix[12]) graph_rgb = counter_rgb;
         else if(c2pix[00]) graph_rgb = counter_rgb;
         else if(c2pix[01]) graph_rgb = counter_rgb;
         else if(c2pix[02]) graph_rgb = counter_rgb;
         else if(c2pix[03]) graph_rgb = counter_rgb;
         else if(c2pix[04]) graph_rgb = counter_rgb;
         else if(c2pix[05]) graph_rgb = counter_rgb;
         else if(c2pix[06]) graph_rgb = counter_rgb;
         else if(c2pix[07]) graph_rgb = counter_rgb;
         else if(c2pix[08]) graph_rgb = counter_rgb;
         else if(c2pix[09]) graph_rgb = counter_rgb;
         else if(c2pix[10]) graph_rgb = counter_rgb;
         else if(c2pix[11]) graph_rgb = counter_rgb;
         else if(c2pix[12]) graph_rgb = counter_rgb;
         else if(tpix) graph_rgb = counter_rgb;
         else
            graph_rgb = 12'b1111_1111_0000; // yellow background
               

endmodule
