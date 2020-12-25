
  parameter REG_MACRO_ADDR = 0;
  parameter REG_MACRO_DATA = 1;
  parameter REG_MACRO_SEL  = 2;
  parameter REG_CONTROL    = 3;
  parameter REG_SPI_ADDR   = 4;
  parameter REG_MACRO_WREN = 5;
  parameter REG_ID         = 5;
  parameter REG_MACROINFO  = 6;

  parameter REG_READ_MACRO = 8'h80;

  parameter REG_ID_VALUE = 8'h11;

  parameter ALL_MACRO_MASK = 8'hFF;

  parameter CPLD_ENONCE_LEN = 8;

  parameter CONTROL_HASH_MASK_START = (1 << 0);
  parameter CONTROL_HASH_MASK_STOP  = (0 << 0);
  parameter CONTROL_PERF_CTR_RUN    = (1 << 2);
  parameter CONTROL_LED_MASK_OFF    = (0 << 3);
  parameter CONTROL_LED_MASK_ON     = (1 << 3);
  parameter CONTROL_CLOCK_OFF       = (1 << 4);
  parameter CONTROL_CLOCK_ON        = (0 << 4);
  parameter CONTROL_ID_HIGH         = (1 << 5);
  parameter CONTROL_ID_LOW          = (0 << 5);

  parameter BROADCAST_ADDR_VALUE = 8'h7f;

  parameter HASH_REG_MIDSTATE     = 8'h00;
  parameter HASH_REG_THRESHOLD    = 8'h20;
  parameter HASH_REG_HEADERDATA   = 8'h24;
  parameter HASH_REG_EXTRANONCE   = 8'h34;
  parameter HASH_REG_NONCEOFFSET  = 8'h38;
  parameter HASH_REG_STRIDEOFFSET = 8'h3B;
