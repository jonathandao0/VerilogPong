// Listing 13.6
module pong_top_an
   (
    input wire clk_in, reset,
    input wire [1:0] btn,
    output wire hsync, vsync,
    output wire [3:0] red, output wire [3:0] grn, output wire [3:0] blu,
    output ctest
   );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [11:0] rgb_reg;
   wire [11:0] rgb_next;
   wire [11:0] rgb;

   // body
   clk_50m_generator clk_gen(clk_in, reset, clk);
   // instantiate vga sync circuit
   vga_sync vsync_unit
      (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));

   // instantiate graphic generator
   pong_graph_animate pong_graph_an_unit
      (.clk(clk), .reset(reset), .btn(btn),
       .video_on(video_on), .pix_x(pixel_x),
       .pix_y(pixel_y), .graph_rgb(rgb_next), .ctest(ctest));

   // rgb buffer
   always @(posedge clk)
      if (pixel_tick)
         rgb_reg <= rgb_next;
   // output
   assign rgb = rgb_reg;

   assign red = (video_on) ? rgb[11:8]: 4'b0;
   assign grn = (video_on) ? rgb[7:4] : 4'b0; 
   assign blu = (video_on) ? rgb[3:0] : 4'b0;
endmodule
