`include "config.svh"
`include "lab_specific_board_config.svh"

// `define USE_DIGILENT_PMOD_MIC3

// `ifdef USE_DIGILENT_PMOD_MIC3
//     `define USE_SDRAM_PINS_AS_GPIO
// `else
//     `define USE_LCD_AS_GPIO
// `endif



`define FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE
        `ifndef FORCE_NO_VIRTUAL_TM1638_USING_GRAPHICS
            `define INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        `endif
    `endif
`endif

// `define REVERSE_KEY not supported, check
// `define REVERSE_LED not supported, check

//`define INSTANTIATE_SOUND_DAC_OUTPUT_INTERFACE_MODULE

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 48,
              pixel_mhz     = 24,

              w_key         = 4,
              w_sw          = 0,
              w_led         = 0,
              w_digit       = 4,

            
              w_gpio        = 0,
              

              screen_width  = 640, // 800
              screen_height = 480, // 600

              w_red         = 5,
              w_green       = 6,
              w_blue        = 5,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                  CLK,
    input                  RESET,

    input  [w_key   - 1:0] KEY_SW,
    // output [w_led   - 1:0] LED,

    output [          7:0] SEG,
    output [w_digit - 1:0] DIG,

    output                 VGA_HSYNC,
    output                 VGA_VSYNC,
    output [w_red   - 1:0] VGA_R,
    output [w_green - 1:0] VGA_G,
    output [w_blue  - 1:0] VGA_B,

    input                  UART_RXD,
    output                 UART_TXD

);

    //------------------------------------------------------------------------

    wire clk =   CLK;
    wire rst = ~ RESET;

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;
    
    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS
        // Instantiate virtual tm1638
        localparam w_lab_key   = w_key,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;
    `else
        // No need in TM1638 in any form
        // We create a dummy seven-segment digit
        // to avoid errors in the labs with seven-segment display

        localparam w_lab_key   = w_key,
                   w_lab_led   = w_led,
                   w_lab_digit = 1;  // w_digit;
    `endif

    //------------------------------------------------------------------------
    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    wire  [              7:0] abcdefgh;

    wire  [w_red       - 1:0] lab_red;
    wire  [w_green     - 1:0] lab_green;
    wire  [w_blue      - 1:0] lab_blue;

    // Graphics

    wire                 display_on;

    wire [w_x     - 1:0] x;
    wire [w_y     - 1:0] y;

    wire  vtm_red, vtm_green, vtm_blue;

    assign VGA_R   = display_on ? lab_red   ^ { w_red   { vtm_red   } } : '0;
    assign VGA_G   = display_on ? lab_green ^ { w_green { vtm_green } } : '0;
    assign VGA_B   = display_on ? lab_blue  ^ { w_blue  { vtm_blue  } } : '0;

    // Sound

    wire [         23:0] mic;
    wire [         15:0] sound;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;
        assign lab_key  = tm_key;

        // assign LED      = w_led' ( lab_led);

    `elsif INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS

        // Virtual tm1638 - tm_keys are input, not output

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY_SW);
        `else
            assign lab_key = ~ KEY_SW;
        `endif

        assign tm_key   = lab_key;
        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        // assign LED      = w_led' ( lab_led);

    `else  // no any form of TM1638

        `ifdef REVERSE_KEY
            `SWAP_BITS (lab_key, ~ KEY_SW);
        `else
            assign lab_key = ~ KEY_SW;
        `endif

        //--------------------------------------------------------------------

        // `ifdef REVERSE_LED
        //     `SWAP_BITS (LED,  lab_led);
        // `else
        //     assign LED =  lab_led;
        // `endif

    `endif  // `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
    # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_key       ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),
        .red           ( lab_red       ),
        .green         ( lab_green     ),
        .blue          ( lab_blue      ),

        .uart_rx       ( UART_RXD      ),
        .uart_tx       ( UART_TXD      ),

        .mic           ( mic           ),
        .sound         ( sound         )
        // ,
        // .gpio          ( GPIO          )
    );

    //------------------------------------------------------------------------

    // assign LED       = ~ lab_led;

    assign SEG       =  abcdefgh;
    assign DIG       =  ~ lab_digit;

    //------------------------------------------------------------------------
    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : g_hgfedcba
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        tm1638_board_controller
        # (
            .clk_mhz  ( clk_mhz    ),
            .w_digit  ( w_tm_digit )
        )
        i_tm1638
        (
            .clk      ( clk        ),
            .rst      ( rst        ),
            .hgfedcba ( hgfedcba   ),
            .digit    ( tm_digit   ),
            .ledr     ( tm_led     ),
            .keys     ( tm_key     ),
            .sio_data ( GPIO [4]   ),  // DIO PIN CN3.9
            .sio_clk  ( GPIO [2]   ),  // CLK PIN CN3.7
            .sio_stb  ( GPIO [0]   )   // STB PIN CN3.5
        );
    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        `ifdef INSTANTIATE_VIRTUAL_TM1638_USING_GRAPHICS

            virtual_tm1638_using_graphics
            # (
                .w_digit       ( w_tm_digit    ),
                .screen_width  ( screen_width  ),
                .screen_height ( screen_height )
            )
            i_tm1638_virtual
            (
                .clk           ( clk           ),
                .rst           ( rst           ),
                .hgfedcba      ( hgfedcba      ),
                .digit         ( tm_digit      ),
                .ledr          ( tm_led        ),
                .keys          ( tm_key        ),
                .x             ( x             ),
                .y             ( y             ),
                .red           ( vtm_red       ),
                .green         ( vtm_green     ),
                .blue          ( vtm_blue      )
            );

        `endif

        //--------------------------------------------------------------------

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz   ),
            .PIXEL_MHZ   ( pixel_mhz )
            // ,
            // // Horizontal constants

            // .H_DISPLAY(           800),  // Horizontal display width
            // .H_FRONT(             56),  // Horizontal right border (front porch)
            // .H_SYNC(              120),  // Horizontal sync width
            // .H_BACK(              64),  // Horizontal left border (back porch)

            // // Vertical constants

            // .V_DISPLAY(600),  // Vertical display height
            // .V_BOTTOM(37),  // Vertical bottom border
            // .V_SYNC(6),  // Vertical sync # lines
            // .V_TOP(23)  // Vertical top border


            // // Horizontal constants

            // .H_DISPLAY(           800),  // Horizontal display width
            // .H_FRONT(             40),  // Horizontal right border (front porch)
            // .H_SYNC(              128),  // Horizontal sync width
            // .H_BACK(              88),  // Horizontal left border (back porch)

            // // Vertical constants

            // .V_DISPLAY(600),  // Vertical display height
            // .V_BOTTOM(1),  // Vertical bottom border
            // .V_SYNC(4),  // Vertical sync # lines
            // .V_TOP(23)  // Vertical top border
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       ( VGA_HSYNC  ),
            .vsync       ( VGA_VSYNC  ),
            .display_on  ( display_on ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

    `endif

    //------------------------------------------------------------------------

//     `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

//         `ifdef USE_DIGILENT_PMOD_MIC3

//             wire [11:0] mic_12;

//             digilent_pmod_mic3_spi_receiver i_microphone
//             (
//                 .clk   ( clk                               ),
//                 .rst   ( rst                               ),
//                 .cs    ( PSEUDO_GPIO_USING_SDRAM_PINS  [0] ),
//                 .sck   ( PSEUDO_GPIO_USING_SDRAM_PINS  [6] ),
//                 .sdo   ( PSEUDO_GPIO_USING_SDRAM_PINS  [4] ),
//                 .value ( mic_12                            )
//             );

//             assign PSEUDO_GPIO_USING_SDRAM_PINS [ 8] = 1'b0;  // GND
//             assign PSEUDO_GPIO_USING_SDRAM_PINS [10] = 1'b1;  // VCC

//             wire [11:0] mic_12_minus_offset = mic_12 - 12'h800;

//             assign mic = { { 12 { mic_12_minus_offset [11] } },
//                            mic_12_minus_offset };

//         //--------------------------------------------------------------------

//         `else  // USE_INMP_441_MIC
// /*
//             inmp441_mic_i2s_receiver
//             # (
//                 .clk_mhz ( clk_mhz   )
//             )
//             i_microphone
//             (
//                 .clk     ( clk       ),
//                 .rst     ( rst       ),
//                 .lr      ( LCD_D [5] ),
//                 .ws      ( LCD_D [3] ),
//                 .sck     ( LCD_D [1] ),
//                 .sd      ( LCD_D [2] ),
//                 .value   ( mic       )
//             );

//             assign LCD_D [6] = 1'b0;  // GND
//             assign LCD_D [4] = 1'b1;  // VCC
// */
//         `endif  // USE_INMP_441_MIC

//     `endif  // INSTANTIATE_MICROPHONE_INTERFACE_MODULE

    //------------------------------------------------------------------------

//     `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE
// /*
//         i2s_audio_out
//         # (
//             .clk_mhz ( clk_mhz   )
//         )
//         inst_audio_out
//         (
//             .clk     ( clk       ),
//             .reset   ( rst       ),
//             .data_in ( sound     ),
//             .mclk    ( LCD_E     ),  // Pin 143
//             .bclk    ( LCD_RS    ),  // Pin 141
//             .lrclk   ( LCD_RW    ),  // Pin 138
//             .sdata   ( LCD_D [0] )   // Pin 142
//         );                           // GND and VCC 3.3V (30-45 mA)
// */
//     `endif

endmodule
