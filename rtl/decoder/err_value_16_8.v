`timescale 1ns/1ps
// Forney algorithm for RS(16,8), GF(256), t=4
// 杈撳叆 位銆佄?鍙婇敊璇綅缃紝璁＄畻閿欒鍊?
module err_value_16_8 #(
    parameter SYM_BW = 8,
    parameter N_NUM  = 16,
    parameter R_NUM  = 8
) (
    input                     clk,
    input                     rst_n,
    input                     start,          // 鑴夊啿锛孋hien done
    input  [SYM_BW*5-1:0]     lamda,          // 位0..位6
    input  [SYM_BW*4-1:0]     omega,          // 惟0..惟5
    input  [SYM_BW*4-1:0]     err_loc,        // 閿欒浣嶇疆鍒楄〃锛堟渶澶?6 涓級
    output reg [SYM_BW*4-1:0] err_val,        // 閿欒鍊硷紙涓?err_loc 瀵归綈锛?
    output reg [SYM_BW*4-1:0] err_loc_out,    // 鐩存帴杞彂 err_loc
    output reg                done
);
    localparam integer T = 4;
    // syndrome 搴忓垪瀵瑰簲鐨勬牴婊¤冻 伪^{idx+1}锛屾棤闇€棰濆鍋忕Щ

    // GF helpers (inlined tables/functions)
    reg [SYM_BW-1:0] EXP[0:255];
    reg [SYM_BW-1:0] LOG[0:255];
    integer _gf_unused;
    initial begin
        EXP[0]=8'h01;EXP[1]=8'h02;EXP[2]=8'h04;EXP[3]=8'h08;EXP[4]=8'h10;EXP[5]=8'h20;EXP[6]=8'h40;EXP[7]=8'h80;
        EXP[8]=8'h1d;EXP[9]=8'h3a;EXP[10]=8'h74;EXP[11]=8'he8;EXP[12]=8'hcd;EXP[13]=8'h87;EXP[14]=8'h13;EXP[15]=8'h26;
        EXP[16]=8'h4c;EXP[17]=8'h98;EXP[18]=8'h2d;EXP[19]=8'h5a;EXP[20]=8'hb4;EXP[21]=8'h75;EXP[22]=8'hea;EXP[23]=8'hc9;
        EXP[24]=8'h8f;EXP[25]=8'h03;EXP[26]=8'h06;EXP[27]=8'h0c;EXP[28]=8'h18;EXP[29]=8'h30;EXP[30]=8'h60;EXP[31]=8'hc0;
        EXP[32]=8'h9d;EXP[33]=8'h27;EXP[34]=8'h4e;EXP[35]=8'h9c;EXP[36]=8'h25;EXP[37]=8'h4a;EXP[38]=8'h94;EXP[39]=8'h35;
        EXP[40]=8'h6a;EXP[41]=8'hd4;EXP[42]=8'hb5;EXP[43]=8'h77;EXP[44]=8'hee;EXP[45]=8'hc1;EXP[46]=8'h9f;EXP[47]=8'h23;
        EXP[48]=8'h46;EXP[49]=8'h8c;EXP[50]=8'h05;EXP[51]=8'h0a;EXP[52]=8'h14;EXP[53]=8'h28;EXP[54]=8'h50;EXP[55]=8'ha0;
        EXP[56]=8'h5d;EXP[57]=8'hba;EXP[58]=8'h69;EXP[59]=8'hd2;EXP[60]=8'hb9;EXP[61]=8'h6f;EXP[62]=8'hde;EXP[63]=8'ha1;
        EXP[64]=8'h5f;EXP[65]=8'hbe;EXP[66]=8'h61;EXP[67]=8'hc2;EXP[68]=8'h99;EXP[69]=8'h2f;EXP[70]=8'h5e;EXP[71]=8'hbc;
        EXP[72]=8'h65;EXP[73]=8'hca;EXP[74]=8'h89;EXP[75]=8'h0f;EXP[76]=8'h1e;EXP[77]=8'h3c;EXP[78]=8'h78;EXP[79]=8'hf0;
        EXP[80]=8'hfd;EXP[81]=8'he7;EXP[82]=8'hd3;EXP[83]=8'hbb;EXP[84]=8'h6b;EXP[85]=8'hd6;EXP[86]=8'hb1;EXP[87]=8'h7f;
        EXP[88]=8'hfe;EXP[89]=8'he1;EXP[90]=8'hdf;EXP[91]=8'ha3;EXP[92]=8'h5b;EXP[93]=8'hb6;EXP[94]=8'h71;EXP[95]=8'he2;
        EXP[96]=8'hd9;EXP[97]=8'haf;EXP[98]=8'h43;EXP[99]=8'h86;EXP[100]=8'h11;EXP[101]=8'h22;EXP[102]=8'h44;EXP[103]=8'h88;
        EXP[104]=8'h0d;EXP[105]=8'h1a;EXP[106]=8'h34;EXP[107]=8'h68;EXP[108]=8'hd0;EXP[109]=8'hbd;EXP[110]=8'h67;EXP[111]=8'hce;
        EXP[112]=8'h81;EXP[113]=8'h1f;EXP[114]=8'h3e;EXP[115]=8'h7c;EXP[116]=8'hf8;EXP[117]=8'hed;EXP[118]=8'hc7;EXP[119]=8'h93;
        EXP[120]=8'h3b;EXP[121]=8'h76;EXP[122]=8'hec;EXP[123]=8'hc5;EXP[124]=8'h97;EXP[125]=8'h33;EXP[126]=8'h66;EXP[127]=8'hcc;
        EXP[128]=8'h85;EXP[129]=8'h17;EXP[130]=8'h2e;EXP[131]=8'h5c;EXP[132]=8'hb8;EXP[133]=8'h6d;EXP[134]=8'hda;EXP[135]=8'ha9;
        EXP[136]=8'h4f;EXP[137]=8'h9e;EXP[138]=8'h21;EXP[139]=8'h42;EXP[140]=8'h84;EXP[141]=8'h15;EXP[142]=8'h2a;EXP[143]=8'h54;
        EXP[144]=8'ha8;EXP[145]=8'h4d;EXP[146]=8'h9a;EXP[147]=8'h29;EXP[148]=8'h52;EXP[149]=8'ha4;EXP[150]=8'h55;EXP[151]=8'haa;
        EXP[152]=8'h49;EXP[153]=8'h92;EXP[154]=8'h39;EXP[155]=8'h72;EXP[156]=8'he4;EXP[157]=8'hd5;EXP[158]=8'hb7;EXP[159]=8'h73;
        EXP[160]=8'he6;EXP[161]=8'hd1;EXP[162]=8'hbf;EXP[163]=8'h63;EXP[164]=8'hc6;EXP[165]=8'h91;EXP[166]=8'h3f;EXP[167]=8'h7e;
        EXP[168]=8'hfc;EXP[169]=8'he5;EXP[170]=8'hd7;EXP[171]=8'hb3;EXP[172]=8'h7b;EXP[173]=8'hf6;EXP[174]=8'hf1;EXP[175]=8'hff;
        EXP[176]=8'he3;EXP[177]=8'hdb;EXP[178]=8'hab;EXP[179]=8'h4b;EXP[180]=8'h96;EXP[181]=8'h31;EXP[182]=8'h62;EXP[183]=8'hc4;
        EXP[184]=8'h95;EXP[185]=8'h37;EXP[186]=8'h6e;EXP[187]=8'hdc;EXP[188]=8'ha5;EXP[189]=8'h57;EXP[190]=8'hae;EXP[191]=8'h41;
        EXP[192]=8'h82;EXP[193]=8'h19;EXP[194]=8'h32;EXP[195]=8'h64;EXP[196]=8'hc8;EXP[197]=8'h8d;EXP[198]=8'h07;EXP[199]=8'h0e;
        EXP[200]=8'h1c;EXP[201]=8'h38;EXP[202]=8'h70;EXP[203]=8'he0;EXP[204]=8'hdd;EXP[205]=8'ha7;EXP[206]=8'h53;EXP[207]=8'ha6;
        EXP[208]=8'h51;EXP[209]=8'ha2;EXP[210]=8'h59;EXP[211]=8'hb2;EXP[212]=8'h79;EXP[213]=8'hf2;EXP[214]=8'hf9;EXP[215]=8'hef;
        EXP[216]=8'hc3;EXP[217]=8'h9b;EXP[218]=8'h2b;EXP[219]=8'h56;EXP[220]=8'hac;EXP[221]=8'h45;EXP[222]=8'h8a;EXP[223]=8'h09;
        EXP[224]=8'h12;EXP[225]=8'h24;EXP[226]=8'h48;EXP[227]=8'h90;EXP[228]=8'h3d;EXP[229]=8'h7a;EXP[230]=8'hf4;EXP[231]=8'hf5;
        EXP[232]=8'hf7;EXP[233]=8'hf3;EXP[234]=8'hfb;EXP[235]=8'heb;EXP[236]=8'hcb;EXP[237]=8'h8b;EXP[238]=8'h0b;EXP[239]=8'h16;
        EXP[240]=8'h2c;EXP[241]=8'h58;EXP[242]=8'hb0;EXP[243]=8'h7d;EXP[244]=8'hfa;EXP[245]=8'he9;EXP[246]=8'hcf;EXP[247]=8'h83;
        EXP[248]=8'h1b;EXP[249]=8'h36;EXP[250]=8'h6c;EXP[251]=8'hd8;EXP[252]=8'had;EXP[253]=8'h47;EXP[254]=8'h8e;EXP[255]=8'h01;
        LOG[0]=8'h00;LOG[1]=8'h00;LOG[2]=8'h01;LOG[3]=8'h19;LOG[4]=8'h02;LOG[5]=8'h32;LOG[6]=8'h1a;LOG[7]=8'hc6;
        LOG[8]=8'h03;LOG[9]=8'hdf;LOG[10]=8'h33;LOG[11]=8'hee;LOG[12]=8'h1b;LOG[13]=8'h68;LOG[14]=8'hc7;LOG[15]=8'h4b;
        LOG[16]=8'h04;LOG[17]=8'h64;LOG[18]=8'he0;LOG[19]=8'h0e;LOG[20]=8'h34;LOG[21]=8'h8d;LOG[22]=8'hef;LOG[23]=8'h81;
        LOG[24]=8'h1c;LOG[25]=8'hc1;LOG[26]=8'h69;LOG[27]=8'hf8;LOG[28]=8'hc8;LOG[29]=8'h08;LOG[30]=8'h4c;LOG[31]=8'h71;
        LOG[32]=8'h05;LOG[33]=8'h8a;LOG[34]=8'h65;LOG[35]=8'h2f;LOG[36]=8'he1;LOG[37]=8'h24;LOG[38]=8'h0f;LOG[39]=8'h21;
        LOG[40]=8'h35;LOG[41]=8'h93;LOG[42]=8'h8e;LOG[43]=8'hda;LOG[44]=8'hf0;LOG[45]=8'h12;LOG[46]=8'h82;LOG[47]=8'h45;
        LOG[48]=8'h1d;LOG[49]=8'hb5;LOG[50]=8'hc2;LOG[51]=8'h7d;LOG[52]=8'h6a;LOG[53]=8'h27;LOG[54]=8'hf9;LOG[55]=8'hb9;
        LOG[56]=8'hc9;LOG[57]=8'h9a;LOG[58]=8'h09;LOG[59]=8'h78;LOG[60]=8'h4d;LOG[61]=8'he4;LOG[62]=8'h72;LOG[63]=8'ha6;
        LOG[64]=8'h06;LOG[65]=8'hbf;LOG[66]=8'h8b;LOG[67]=8'h62;LOG[68]=8'h66;LOG[69]=8'hdd;LOG[70]=8'h30;LOG[71]=8'hfd;
        LOG[72]=8'he2;LOG[73]=8'h98;LOG[74]=8'h25;LOG[75]=8'hb3;LOG[76]=8'h10;LOG[77]=8'h91;LOG[78]=8'h22;LOG[79]=8'h88;
        LOG[80]=8'h36;LOG[81]=8'hd0;LOG[82]=8'h94;LOG[83]=8'hce;LOG[84]=8'h8f;LOG[85]=8'h96;LOG[86]=8'hdb;LOG[87]=8'hbd;
        LOG[88]=8'hf1;LOG[89]=8'hd2;LOG[90]=8'h13;LOG[91]=8'h5c;LOG[92]=8'h83;LOG[93]=8'h38;LOG[94]=8'h46;LOG[95]=8'h40;
        LOG[96]=8'h1e;LOG[97]=8'h42;LOG[98]=8'hb6;LOG[99]=8'ha3;LOG[100]=8'hc3;LOG[101]=8'h48;LOG[102]=8'h7e;LOG[103]=8'h6e;
        LOG[104]=8'h6b;LOG[105]=8'h3a;LOG[106]=8'h28;LOG[107]=8'h54;LOG[108]=8'hfa;LOG[109]=8'h85;LOG[110]=8'hba;LOG[111]=8'h3d;
        LOG[112]=8'hca;LOG[113]=8'h5e;LOG[114]=8'h9b;LOG[115]=8'h9f;LOG[116]=8'h0a;LOG[117]=8'h15;LOG[118]=8'h79;LOG[119]=8'h2b;
        LOG[120]=8'h4e;LOG[121]=8'hd4;LOG[122]=8'he5;LOG[123]=8'hac;LOG[124]=8'h73;LOG[125]=8'hf3;LOG[126]=8'ha7;LOG[127]=8'h57;
        LOG[128]=8'h07;LOG[129]=8'h70;LOG[130]=8'hc0;LOG[131]=8'hf7;LOG[132]=8'h8c;LOG[133]=8'h80;LOG[134]=8'h63;LOG[135]=8'h0d;
        LOG[136]=8'h67;LOG[137]=8'h4a;LOG[138]=8'hde;LOG[139]=8'hed;LOG[140]=8'h31;LOG[141]=8'hc5;LOG[142]=8'hfe;LOG[143]=8'h18;
        LOG[144]=8'he3;LOG[145]=8'ha5;LOG[146]=8'h99;LOG[147]=8'h77;LOG[148]=8'h26;LOG[149]=8'hb8;LOG[150]=8'hb4;LOG[151]=8'h7c;
        LOG[152]=8'h11;LOG[153]=8'h44;LOG[154]=8'h92;LOG[155]=8'hd9;LOG[156]=8'h23;LOG[157]=8'h20;LOG[158]=8'h89;LOG[159]=8'h2e;
        LOG[160]=8'h37;LOG[161]=8'h3f;LOG[162]=8'hd1;LOG[163]=8'h5b;LOG[164]=8'h95;LOG[165]=8'hbc;LOG[166]=8'hcf;LOG[167]=8'hcd;
        LOG[168]=8'h90;LOG[169]=8'h87;LOG[170]=8'h97;LOG[171]=8'hb2;LOG[172]=8'hdc;LOG[173]=8'hfc;LOG[174]=8'hbe;LOG[175]=8'h61;
        LOG[176]=8'hf2;LOG[177]=8'h56;LOG[178]=8'hd3;LOG[179]=8'hab;LOG[180]=8'h14;LOG[181]=8'h2a;LOG[182]=8'h5d;LOG[183]=8'h9e;
        LOG[184]=8'h84;LOG[185]=8'h3c;LOG[186]=8'h39;LOG[187]=8'h53;LOG[188]=8'h47;LOG[189]=8'h6d;LOG[190]=8'h41;LOG[191]=8'ha2;
        LOG[192]=8'h1f;LOG[193]=8'h2d;LOG[194]=8'h43;LOG[195]=8'hd8;LOG[196]=8'hb7;LOG[197]=8'h7b;LOG[198]=8'ha4;LOG[199]=8'h76;
        LOG[200]=8'hc4;LOG[201]=8'h17;LOG[202]=8'h49;LOG[203]=8'hec;LOG[204]=8'h7f;LOG[205]=8'h0c;LOG[206]=8'h6f;LOG[207]=8'hf6;
        LOG[208]=8'h6c;LOG[209]=8'ha1;LOG[210]=8'h3b;LOG[211]=8'h52;LOG[212]=8'h29;LOG[213]=8'h9d;LOG[214]=8'h55;LOG[215]=8'haa;
        LOG[216]=8'hfb;LOG[217]=8'h60;LOG[218]=8'h86;LOG[219]=8'hb1;LOG[220]=8'hbb;LOG[221]=8'hcc;LOG[222]=8'h3e;LOG[223]=8'h5a;
        LOG[224]=8'hcb;LOG[225]=8'h59;LOG[226]=8'h5f;LOG[227]=8'hb0;LOG[228]=8'h9c;LOG[229]=8'ha9;LOG[230]=8'ha0;LOG[231]=8'h51;
        LOG[232]=8'h0b;LOG[233]=8'hf5;LOG[234]=8'h16;LOG[235]=8'heb;LOG[236]=8'h7a;LOG[237]=8'h75;LOG[238]=8'h2c;LOG[239]=8'hd7;
        LOG[240]=8'h4f;LOG[241]=8'hae;LOG[242]=8'hd5;LOG[243]=8'he9;LOG[244]=8'he6;LOG[245]=8'he7;LOG[246]=8'had;LOG[247]=8'he8;
        LOG[248]=8'h74;LOG[249]=8'hd6;LOG[250]=8'hf4;LOG[251]=8'hea;LOG[252]=8'ha8;LOG[253]=8'h50;LOG[254]=8'h58;LOG[255]=8'haf;
    end

    function automatic [SYM_BW-1:0] gf_mul;
        input [SYM_BW-1:0] a;
        input [SYM_BW-1:0] b;
        reg [8:0] sum;
    begin
        if (a == 0 || b == 0) begin
            gf_mul = {SYM_BW{1'b0}};
        end else begin
            sum = LOG[a] + LOG[b];
            if (sum >= 9'd255)
                sum = sum - 9'd255;
            gf_mul = EXP[sum[7:0]];
        end
    end
    endfunction

    function automatic [SYM_BW-1:0] gf_inv;
        input [SYM_BW-1:0] a;
        reg [8:0] idx;
    begin
        if (a == 0) begin
            gf_inv = {SYM_BW{1'b0}};
        end else begin
            idx = 9'd255 - LOG[a];
            if (idx >= 9'd255)
                idx = idx - 9'd255;
            gf_inv = EXP[idx[7:0]];
        end
    end
    endfunction

    function automatic [SYM_BW-1:0] gf_pow;
        input integer idx;
        integer adj;
    begin
        adj = idx % 255;
        if (adj < 0)
            adj = adj + 255;
        gf_pow = EXP[adj[7:0]];
    end
    endfunction

    reg [SYM_BW-1:0] lam[0:T];
    reg [SYM_BW-1:0] omg[0:T-1];
    reg [SYM_BW-1:0] loc_in[0:T-1];
    reg [SYM_BW-1:0] err_val_arr[0:T-1];
    reg [SYM_BW-1:0] err_loc_arr[0:T-1];

    reg [2:0] idx; // 褰撳墠澶勭悊绗嚑涓敊璇?0..5
    reg       running;

    // next-state
    reg [2:0] idx_n;
    reg       running_n;
    reg       done_n;
    reg [SYM_BW-1:0] err_val_arr_n[0:T-1];
    reg [SYM_BW-1:0] err_loc_arr_n[0:T-1];

    // 涓存椂
    reg [SYM_BW-1:0] x;         // X^{-1} = 伪^{err_loc+1}锛坋rr_loc 涓?0-based锛?
    reg [SYM_BW-1:0] x_pow;
    reg [SYM_BW-1:0] omega_eval;
    reg [SYM_BW-1:0] lambda_der;
    reg [SYM_BW-1:0] err_calc;
    integer i;

    // latch 杈撳叆
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= T; i = i + 1) lam[i] <= {SYM_BW{1'b0}};
            for (i = 0; i < T; i = i + 1) begin
                omg[i]    <= {SYM_BW{1'b0}};
                loc_in[i] <= {SYM_BW{1'b0}};
            end
        end else if (start) begin
            for (i = 0; i <= T; i = i + 1) lam[i] <= lamda[i*SYM_BW +: SYM_BW];
            for (i = 0; i < T; i = i + 1) begin
                omg[i]    <= omega[i*SYM_BW +: SYM_BW];
                loc_in[i] <= err_loc[i*SYM_BW +: SYM_BW];
            end
        end
    end

    // 缁勫悎锛欶orney 杩唬
    always @* begin
        for (i = 0; i < T; i = i + 1) begin
            err_val_arr_n[i] = err_val_arr[i];
            err_loc_arr_n[i] = err_loc_arr[i];
        end
        idx_n     = idx;
        running_n = running;
        done_n    = 1'b0;

        x          = {SYM_BW{1'b0}};
        x_pow      = {SYM_BW{1'b0}};
        omega_eval = {SYM_BW{1'b0}};
        lambda_der = {SYM_BW{1'b0}};
        err_calc   = {SYM_BW{1'b0}};

        if (start) begin
            running_n = 1'b1;
            idx_n     = 3'd0;
            for (i = 0; i < T; i = i + 1) begin
                err_val_arr_n[i] = {SYM_BW{1'b0}};
                err_loc_arr_n[i] = {SYM_BW{1'b1}};
            end
        end else if (running) begin
            if (loc_in[idx] == {SYM_BW{1'b1}}) begin
                // 绌烘Ы锛氫繚鎸?0
                err_calc           = {SYM_BW{1'b0}};
                err_val_arr_n[idx] = {SYM_BW{1'b0}};
                err_loc_arr_n[idx] = loc_in[idx];
            end else begin
                integer pos_int;
                pos_int   = loc_in[idx];
                x         = gf_pow(pos_int + 1);   // X^{-1} = 伪^{loc+1}
                omega_eval = omg[0];
                x_pow      = x;
                for (i = 1; i < T; i = i + 1) begin
                    omega_eval = omega_eval ^ gf_mul(omg[i], x_pow);
                    x_pow      = gf_mul(x_pow, x);
                end

                // 位'(x) = 位1 + 位3*x^2 + 位5*x^4 锛堢壒寰?2锛氬伓娆￠」瀵兼暟涓?0锛?
                lambda_der = lam[1];
                x_pow = gf_mul(x, x);                // x^2
                lambda_der = lambda_der ^ gf_mul(lam[3], x_pow);
                                if (lambda_der != 0)
                    err_calc = gf_mul(omega_eval, gf_inv(lambda_der));
                else
                    err_calc = {SYM_BW{1'b0}};

                err_val_arr_n[idx] = err_calc;
                err_loc_arr_n[idx] = loc_in[idx];
            end

            if (idx == T-1) begin
                running_n = 1'b0;
                done_n    = 1'b1;
            end else begin
                idx_n = idx + 3'd1;
            end
        end
    end

    // 鏃跺簭瀵勫瓨
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx     <= 3'd0;
            running <= 1'b0;
            done    <= 1'b0;
            for (i = 0; i < T; i = i + 1) begin
                err_val_arr[i] <= {SYM_BW{1'b0}};
                err_loc_arr[i] <= {SYM_BW{1'b1}};
            end
        end else begin
            idx     <= idx_n;
            running <= running_n;
            done    <= done_n;
            for (i = 0; i < T; i = i + 1) begin
                err_val_arr[i] <= err_val_arr_n[i];
                err_loc_arr[i] <= err_loc_arr_n[i];
            end
        end
    end

    // 鎵撳寘杈撳嚭
    always @* begin
        for (i = 0; i < T; i = i + 1) begin
            err_val[i*SYM_BW +: SYM_BW]     = err_val_arr[i];
            err_loc_out[i*SYM_BW +: SYM_BW] = err_loc_arr[i];
        end
    end

endmodule


