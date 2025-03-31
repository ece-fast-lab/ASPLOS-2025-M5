	component pll_0 is
		port (
			inclk       : in  std_logic := 'X'; -- clk
			clock_div1x : out std_logic;        -- clk
			clock_div2x : out std_logic;        -- clk
			clock_div4x : out std_logic         -- clk
		);
	end component pll_0;

	u0 : component pll_0
		port map (
			inclk       => CONNECTED_TO_inclk,       --       inclk.clk
			clock_div1x => CONNECTED_TO_clock_div1x, -- clock_div1x.clk
			clock_div2x => CONNECTED_TO_clock_div2x, -- clock_div2x.clk
			clock_div4x => CONNECTED_TO_clock_div4x  -- clock_div4x.clk
		);

