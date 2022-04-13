unit com;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  comunicador,
  funcoes;

  { TDCom }
  type
  TRetorno = procedure(VP_Codigo:integer;VP_Dados:string);  stdcall;

  ThProcesso = class(TThread)
      private
       fdados : AnsiString;
       fprocedimento:TRetorno;
      protected
        procedure Execute; override;
      public
       constructor Create(VP_Suspenso:Boolean;VP_Dados : AnsiString; VP_Procedimento:TRetorno);

  end;



  TDCom = class(TDataModule)
  private

  end;

function inicializar() : integer;  stdcall;
function finalizar() : integer;  stdcall;
function login(VP_Host : AnsiString; VP_Porta : integer; VP_ChaveTerminal : AnsiString;
         VP_Versao_Comunicacao : integer;VP_Senha:AnsiString;VP_Tipo : AnsiString;var VO_Mensagem:AnsiString) : integer;  stdcall;
function solicitacao(VP_Dados : AnsiString; VP_Procedimento:TRetorno) : Integer;  stdcall;
function solicitacaoblocante(VP_Dados : AnsiString; var VO_Retorno:AnsiString):Integer;  stdcall;
function opentefstatus(var VO_StatusRetorno : Integer): Integer; stdcall;

var
  DCom: TDCom;
  V_Inicializado:Boolean = False;
  F_ChaveTerminal : AnsiString;
  F_Versao_Comunicacao : Integer;


  Const
  C_lib_versao: array  [0..2] of Integer = (1,0,0) ;

implementation

{$R *.lfm}
{ TDCom }


constructor ThProcesso.Create(VP_Suspenso:Boolean;VP_Dados : AnsiString; VP_Procedimento:TRetorno);

begin
  FreeOnTerminate := True;
  fdados:=VP_Dados;
  fprocedimento:=VP_Procedimento;
  inherited Create(VP_Suspenso);

end;

procedure ThProcesso.Execute;

begin
  sleep(5000);
  fprocedimento(1,'tok'+fdados);
end;

function inicializar() : Integer; stdcall;
begin

 if not Assigned(DComunicador) then
 DComunicador:=TDComunicador.Create(nil);

 DComunicador.CriptoRsa.GenerateKeyPair;

 DComunicador.V_ConexaoEscuta:=TTConexao.Create;
 DComunicador.V_ConexaoSolicita:=TTConexao.Create;

 Result:=0;

end;

function finalizar() : integer; stdcall;
begin
 DComunicador.Free;

 Result:=0;
end;

function login(VP_Host : AnsiString; VP_Porta : integer; VP_ChaveTerminal : AnsiString;
         VP_Versao_Comunicacao : integer;VP_Senha:AnsiString;VP_Tipo:AnsiString;var VO_Mensagem:AnsiString) : integer;  stdcall;
var
  VL_Mensagem:TMensagem;
  VL_S:String;
  VL_Erro:String;
begin
 VL_S:='';
 VL_Mensagem:=TMensagem.Create;
try
  if Length(VP_host)=0 then
  begin
     result :=9;
     exit;
  end;
  if VP_Porta < 1 then
  begin
     result :=11;
     exit;
  end;
  if VP_Versao_Comunicacao<1 then
  begin
     result := 13;
     exit;
  end;
  if length(VP_ChaveTerminal)=0 then
  begin
     result :=15;
     exit;
  end;
  if Length(VP_Tipo)=0 then
  begin
     result:=42;
     Exit;
  end;
  if (((DComunicador.V_ConexaoSolicita.ServidorHost<> VP_Host) or
     (DComunicador.V_ConexaoSolicita.ServidorPorta<> VP_Porta) or
     (F_ChaveTerminal <> VP_ChaveTerminal) or
     (F_Versao_Comunicacao <> VP_Versao_Comunicacao)) and
     (DComunicador.V_ConexaoSolicita.Status<>csDesconectado)) then
     DComunicador.DesconectarSolicitacao;
  //variaves compativeis
  DComunicador.V_ConexaoSolicita.ServidorHost:= VP_Host;
  DComunicador.V_ConexaoSolicita.ServidorPorta:= VP_Porta;
  F_ChaveTerminal := VP_ChaveTerminal;
  F_Versao_Comunicacao := VP_Versao_Comunicacao;
  result:=DComunicador.ConectarSolicitacao;
  if Result<>0 then
  Exit;
  if DComunicador.V_ConexaoSolicita.Status=csLogado then
  begin
     Result:=0;
     Exit;
  end;
  if DComunicador.V_ConexaoSolicita.Status=csChaveado then
  begin
     VL_Mensagem.Limpar;
     VL_Mensagem.AddComando('0001','');
     VL_Mensagem.AddTag('0002',VP_ChaveTerminal);
     VL_Mensagem.AddTag('0005',IntToStr(C_lib_versao[0])+'.'+IntToStr(C_lib_versao[1])+'.'+IntToStr(C_lib_versao[2]));
     VL_Mensagem.AddTag('0006',IntToStr(C_lib_versao[0]));
     VL_Mensagem.AddTag('0035',VP_Senha);
     VL_Mensagem.AddTag('0037',VP_Tipo);
     //envia ao cliente
     result:= DComunicador.TransmiteSolicitacaoCliente(VL_Mensagem,VL_Mensagem,nil);
     if result<>0 then
     Exit;
     result:=VL_Mensagem.GetComando(VL_S);
     if result<>0then
     Exit;

     VL_Mensagem.TagToStr(VO_Mensagem);

     if VL_S='0028' then
     DComunicador.V_ConexaoSolicita.Status:=csLogado;
  end;

finally
  VL_Mensagem.free;
end;

end;
function solicitacao(VP_Dados : AnsiString; VP_Procedimento:TRetorno):Integer;  stdcall;
var

  //v_d:^TResposta;
  //v_p:TRetorno;
  //i:PInteger;
  //i:integer;

 VL_Th:ThProcesso;
begin
  //v_d:=RetornoDados;

  //v_d^.codigo:=LongInt(@RetornoDados);
  //v_d^.Dados:='ok';

   //Result.Codigo:=1;
   //Result.Dados:='ok2';
  //v_p:=TRetorno(procedimento);

  //new(s);
  //s^:='joia';
  Result:=1;

  VL_Th:=ThProcesso.Create(True,VP_Dados,VP_Procedimento);
  VL_Th.Start;

end;

function solicitacaoblocante(VP_Dados : AnsiString; var VO_Retorno:AnsiString):Integer;  stdcall;
var
VL_Mensagem:TMensagem;
begin
VL_Mensagem:=TMensagem.Create;
try
  VL_Mensagem.CarregaTags(VP_Dados);
  Result:= DComunicador.TransmiteSolicitacaoCliente(VL_Mensagem,VL_Mensagem,nil);
  VL_Mensagem.TagToStr(VO_Retorno);
finally
  VL_Mensagem.Free;
end;

end;

function opentefstatus(var VO_StatusRetorno : integer): Integer; stdcall;
begin
result := 0;
VO_StatusRetorno:= ord(DComunicador.V_ConexaoSolicita.Status);
end;



end.

