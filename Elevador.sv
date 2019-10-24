/**
 *  Questão: Elevador
 * 
 *  Descrição:
 *    Implemente o circuito de controle de um elevador.
 *    O elevador leva pessoas do andar A para o andar B.
 *    Ele não leva pessoas de B para A. A capacidade máxima do elevador é de
 *    2 pessoas.
 *    
 *    Quando a porta no andar A estiver aberta, pessoas podem entrar no
 *    elevador, uma a cada clock. Tem um sensor na porta que detecta a
 *    entrada de uma pessoa.
 *    Quando tiverem 2 pessoas dentro do elevador, a porta se fecha e o
 *    elevador vai para o andar B.
 *    Quando tiver somente 1 pessoa dentro do elevador mas ela já esperou
 *    durante 2 ciclos de clock, a porta se fecha e o elevador vai para o
 *    andar B.
 *    Depois de 2 ciclos de clock ele chega no andar B, a porta se abre por
 *    tantos ciclos de clock quanto tem passageiros, e volta para o andar A
 *    em 2 ciclos de clock.
 *    No andar A a porta se abre e tudo recomeça do início.
 *    
 *    No reset, a porta deve estar aberta e o elevador deve estar no andar A
 *    e ele estar vazio.
 *    A entrada de uma pessoa é sinalizada na subida do clock.
 *    Se o sinal fica ativo durante duas subidas de clock, duas pessoas entraram.
 *    
 *
 *  Entradas:
 *    - clock - 0,5Hz, aparecendo em SEG[7]
 *    - reset - SWI[7]
 *    - pessoa - sinaliza entrada de 1 pessoa no elevador, SWI[0]
 *
 *  Saídas:
 *    - andar - 0: andar A
 *              1: andar B
 *              LED[0]
 *    - porta - sinaliza que a porta está aberta, LED[1]
 *
 *  Autor: Marcus Vinícius
 */

parameter NINSTR_BITS = 32;
parameter NBITS_TOP = 8, NREGS_TOP = 32, NBITS_LCD = 64;
module top(input  logic clk_2,
           input  logic [NBITS_TOP-1:0] SWI,
           output logic [NBITS_TOP-1:0] LED,
           output logic [NBITS_TOP-1:0] SEG,
           output logic [NBITS_LCD-1:0] lcd_a, lcd_b,
           output logic [NINSTR_BITS-1:0] lcd_instruction,
           output logic [NBITS_TOP-1:0] lcd_registrador [0:NREGS_TOP-1],
           output logic [NBITS_TOP-1:0] lcd_pc, lcd_SrcA, lcd_SrcB,
             lcd_ALUResult, lcd_Result, lcd_WriteData, lcd_ReadData, 
           output logic lcd_MemWrite, lcd_Branch, lcd_MemtoReg, lcd_RegWrite);

//Estados
enum logic [2:0] { andarA, caminho, andarB} state;

logic reset, pessoa, porta, andar;
logic [1:0] cont_pessoas;
logic [1:0] cont_cloks;
logic clk1s, clk2s;

//Entradas
always_comb begin
  reset <= SWI[7];
  pessoa <= SWI[0];
end

//1 Hz (1s)
always_ff @(posedge clk_2) begin
  clk1s <= ~clk1s;
end

//0.5 Hz (2s)
always_ff @(posedge clk1s) begin
  clk2s <= ~clk2s;
end

//FSM
always_ff @(posedge clk2s) begin
  if(reset) begin
    porta <=1;
    andar <= 0;
    cont_pessoas <= 0;
    cont_cloks = 0;
    state<= andarA;
  end 
  else begin
    unique case(state)

      andarA: begin
        andar <= 0;
        porta <= 1;
        if(pessoa) cont_pessoas<= cont_pessoas +1;
        if(cont_pessoas==2) begin
          porta<=0;
          state<= caminho;
        end
        else if (cont_pessoas ==1)begin
          if(cont_cloks==2) begin
            cont_cloks = 0;
            state<= caminho;
          end
          cont_cloks = cont_cloks+1;
        end
      end

      caminho: begin
        porta<= 0;
        cont_cloks = cont_cloks +1;
        if(cont_cloks==2)begin
          cont_cloks = cont_pessoas;
          if(andar ==0) state<= andarB;
          else state<= andarA;
        end
      end

      andarB: begin
        andar<=1;
        porta<=1;
        cont_cloks= cont_cloks -1;
        if(cont_cloks==0)begin
          cont_cloks = 0;
          cont_pessoas <= 0;
          state <=caminho;
        end
      end
    endcase
  end
end

//Saidas
always_comb begin
  LED[0] <= andar;
  LED[1] <= porta;
  LED[7:6] <= cont_pessoas;
  SEG[7] <= clk2s;
end

endmodule