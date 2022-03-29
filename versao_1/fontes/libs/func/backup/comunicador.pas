unit comunicador;


{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LbRSA,StrUtils, LbClass, IdTCPClient, IdTCPServer, IdComponent,
  IdCustomTCPServer,funcoes, IdContext,LbAsym;

type

  { TDComunicador }

 TRecebe = procedure (VP_Dados:String);
 TKey = array [0..31] of Byte;
 TConexaoStatus= (csDesconectado,csLink,csChaveado,csLogado);
 TTConexaoTipo = (cFConexaoEscuta,cFConexaoSolicita);

 TTChaveComunicacao = record
  ID:Integer;
  ChaveComunicacao :String;
 end;

 TTChaveConexao = class
   private
   fChaveComunicacao : array of TTChaveComunicacao;
   fContador:Integer;
   public
    constructor Create;
    function getChave(VP_ID:Integer):TTChaveComunicacao;
    function addChave(VP_ChaveComunicacao:String):Integer;

 end;

 TTConexao = class
   Aes:TLbRijndael;
   Rsa:TLbRSA;
   ClienteIp:String;
   ClientePorta:Integer;
   ServidorHost:String;
   ServidorPorta:Integer;
   Hora:TDateTime;
   ID:Integer;
   ChaveComunicacaoIDX:Integer;
   ModuloPublico:String;
   ExpoentePublico:String;
   Status:TConexaoStatus;
   public
     constructor Create;
     destructor Destroy; override;
     procedure setModuloPublico(VP_Dados:string);
     procedure setExpoentePublico(VP_Dados:string);
     procedure setChaveComunicacao(VP_Chave:string);
     function getChavePublica:string;
     function getChaveComunicacao:String;
 end;

 TThRecebe = class(TThread)
      private
       fdados : AnsiString;
       fprocedimento:TRecebe;
      protected
        procedure Execute; override;
      public
        constructor Create(VP_Suspenso:Boolean;VP_Procedimento:TRecebe);
  end;

  TDComunicador = class(TDataModule)
    IdTCPServerCaixa: TIdTCPServer;
    IdTCPServerLib: TIdTCPServer;
    IdTCPSolicita: TIdTCPClient;
    IdTCPEscuta: TIdTCPClient;
    CriptoAes: TLbRijndael;
    CriptoRsa: TLbRSA;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure IdTCPEscutaConnected(Sender: TObject);
    procedure IdTCPEscutaDisconnected(Sender: TObject);
    procedure IdTCPServerCaixaConnect(AContext: TIdContext);
    procedure IdTCPServerCaixaExecute(AContext: TIdContext);
    procedure IdTCPServerLibConnect(AContext: TIdContext);
    procedure IdTCPServerLibExecute(AContext: TIdContext);
    procedure IdTCPSolicitaConnected(Sender: TObject);
    procedure IdTCPSolicitaDisconnected(Sender: TObject);
  private

  public
    V_Chave_Terminal : String;
    V_Versao_Comunicacao : Integer;
    V_ThRecebe:TThRecebe;
    V_ConexaoEscuta,V_ConexaoSolicita:TTConexao;
    V_ChavesDasConexoes:TTChaveConexao;

    function ConectarSolicitacao:Integer;
    function TransmiteSolicitacaoCliente(var VO_Dados:TMensagem;var VO_Retorno:TMensagem; VP_Procedimento:TRecebe):Integer;
    procedure iniciaescuta(VP_Procedimento:TRecebe);
    function conectaescuta:Integer;
    function EnviarCliente(VL_Mensage:TMensagem;VP_AContext:TIdContext):Integer;
    function comando0001(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;
    function comando0021(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;
    function comando000A(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;

  end;

var
  DComunicador: TDComunicador;
implementation

{$R *.lfm}

{ TDComunicador }

function TDComunicador.ConectarSolicitacao:Integer;
var
  VL_Mensagem:TMensagem;
  VL_S:String;
  VL_Dados:String;
  VL_ChaveComunicacao:String;
  VL_OK:String;
  VL_ChaveComunicacaoIDX:String;
  VL_ExpoentePublico,VL_ModuloPublico:String;

begin

VL_Mensagem:=TMensagem.Create;
VL_S:='';
VL_ModuloPublico:='';
VL_ExpoentePublico:='';
VL_ChaveComunicacao:='';
VL_ChaveComunicacaoIDX:='';
VL_OK:='';
VL_Dados:='';
try
 if (V_ConexaoSolicita.Status=csChaveado) or (V_ConexaoSolicita.Status=csLogado) then
 begin
  Result:=0;
  exit;
 end;


 if DComunicador.IdTCPSolicita.Connected then
 DComunicador.IdTCPSolicita.Disconnect;

 DComunicador.IdTCPSolicita.Host:=V_ConexaoSolicita.ServidorHost;
 DComunicador.IdTCPSolicita.Port:=V_ConexaoSolicita.ServidorPorta;

 DComunicador.IdTCPSolicita.Connect;

 if DComunicador.IdTCPSolicita.Connected=False then
 begin
   Result:=26;
   Exit;
 end;

 VL_Mensagem.Limpar;

 VL_Mensagem.AddComando('0021','');
 VL_Mensagem.AddTag('0022',IntToStr(V_ConexaoSolicita.ChaveComunicacaoIDX));
 VL_Mensagem.AddTag('0008',V_ConexaoSolicita.ModuloPublico);
 VL_Mensagem.AddTag('0027',V_ConexaoSolicita.ExpoentePublico);

 if V_ConexaoSolicita.ChaveComunicacaoIDX>0 then
 VL_Mensagem.AddTag('0023',V_ConexaoSolicita.Aes.EncryptString('OK'));

 Result:=VL_Mensagem.TagToStr(VL_S);
 if Result<>0 then
 Exit;

 DComunicador.IdTCPSolicita.Socket.WriteLn(VL_S);

 VL_S:=DComunicador.IdTCPSolicita.Socket.ReadLn;

 Result:=VL_Mensagem.CarregaTags(VL_S);

 if Result<>0 then
  Exit;

 VL_Mensagem.GetComando(VL_Dados);

 if VL_Dados='0024' then
 begin
   V_ConexaoSolicita.Status:=csChaveado;
   Result:=0;
   Exit;
 end;

 if VL_Dados='0026' then
  begin
    VL_Mensagem.GetTag('0026',VL_Dados);
    Result:=StrToInt(VL_Dados);
    Exit;
  end;

 if VL_Dados='0025' then
  begin
  VL_Mensagem.GetTag('0008',VL_ModuloPublico);
  VL_Mensagem.GetTag('0027',VL_ExpoentePublico);
  VL_Mensagem.GetTag('0009',VL_ChaveComunicacao);
  VL_Mensagem.GetTag('0022',VL_ChaveComunicacaoIDX);
  VL_Mensagem.GetTag('0023',VL_OK);

  V_ConexaoSolicita.setExpoentePublico(VL_ExpoentePublico);
  V_ConexaoSolicita.setModuloPublico(VL_ModuloPublico);
  VL_ChaveComunicacao:=V_ConexaoSolicita.Rsa.DecryptString(VL_ChaveComunicacao);
  V_ConexaoSolicita.setChaveComunicacao(VL_ChaveComunicacao);
  V_ConexaoSolicita.ChaveComunicacaoIDX:=StrToInt(VL_ChaveComunicacaoIDX);
  VL_OK:=V_ConexaoSolicita.Aes.DecryptString(VL_OK);


  if VL_OK<>'OK' then
   begin
   Result:=32;
   Exit
   end;
  V_ConexaoSolicita.Status:=csChaveado;
  end;


finally
  VL_Mensagem.Free;
end;

end;


constructor TTChaveConexao.Create;
begin
  fContador:=0;
  inherited Create;
end;



function TTChaveConexao.getChave(VP_ID:Integer):TTChaveComunicacao;
var
i:Integer;
begin
 for i:=0 to Length(fChaveComunicacao)-1 do
 begin
  if VP_ID=fChaveComunicacao[i].ID then
  begin
   Result:=fChaveComunicacao[i];
   Exit;
  end;
 end;
end;

function TTChaveConexao.addChave(VP_ChaveComunicacao:String):Integer;
begin
 fContador:=fContador+1;
 SetLength(fChaveComunicacao,Length(fChaveComunicacao)+1);
 fChaveComunicacao[Length(fChaveComunicacao)-1].ID:=fContador;
 fChaveComunicacao[Length(fChaveComunicacao)-1].ChaveComunicacao:=VP_ChaveComunicacao;
 Result:=fContador;

end;


constructor TTConexao.Create;
var
  VL_Key:TMemoryStream;
begin
  Status:=csDesconectado;

  ServidorHost:='';
  ServidorPorta:=0;

  ClienteIp:='';
  ClientePorta:=0;


  VL_Key:=TMemoryStream.Create;
  Aes:=TLbRijndael.Create(nil);
  Rsa:=TLbRSA.Create(nil);

  Aes.KeySize:=DComunicador.CriptoAes.KeySize;
  Aes.CipherMode:=DComunicador.CriptoAes.CipherMode;
  Aes.GenerateRandomKey;

  Rsa.KeySize:=DComunicador.CriptoRsa.KeySize;


  DComunicador.CriptoRsa.PrivateKey.StoreToStream(VL_Key);
  VL_Key.Position:=0;
  Rsa.PrivateKey.LoadFromStream(VL_Key);

  ExpoentePublico:=DComunicador.CriptoRsa.PublicKey.ExponentAsString;
  ModuloPublico:=DComunicador.CriptoRsa.PublicKey.ModulusAsString;

  inherited Create;
end;

destructor TTConexao.Destroy;
begin

  Aes.Free;
  Rsa.Free;
  inherited Destroy;
end;


procedure TTConexao.setModuloPublico(VP_Dados:string);
begin
 Rsa.PublicKey.ModulusAsString:=VP_Dados;
end;

procedure TTConexao.setExpoentePublico(VP_Dados:string);
begin
 Rsa.PublicKey.ExponentAsString:=VP_Dados;
end;

function TTConexao.getChavePublica:String;
var
 i:Integer;
 h:Array of byte;
 s:string;
 Key:TMemoryStream;
begin
 Key:=TMemoryStream.Create;

 Rsa.PublicKey.StoreToStream(Key);

 if Key.Size>0 then
 SetLength(h,Key.Size);
 Key.Position:=0;
 Key.ReadBuffer(pointer(h)^,Key.Size);

 s:='';
 for i:=0 to Length(h)-1 do
 begin
  s:=s+HexStr(h[i],2);
 end;
 Result:=s;
 Key.Free;

end;


function TTConexao.getChaveComunicacao:String;
var
 s:string;
 i:Integer;
 Key : array [0..31] of Byte;
begin
  s:='';
  Aes.GetKey(Key);
  for i:=0 to Length(key)-1 do
  begin
   s:=s+HexStr(key[i],2);
  end;
  Result:=s;
end;

procedure TTConexao.setChaveComunicacao(VP_Chave:string);
var
 i:Integer;
 c:string;
 Key : array [0..31] of Byte;
begin
 if not Length(VP_Chave)>0 then
 Exit;
 for i:=0 to Length(VP_Chave)div 2 -1 do
 begin
  c:=copy(VP_Chave,((1+i)*2)-1,2);
  Key[i]:=Hex2Dec(c);
 end;
 Aes.SetKey(Key);
end;


constructor TThRecebe.Create(VP_Suspenso:Boolean; VP_Procedimento:TRecebe);
begin
  FreeOnTerminate := True;
  fprocedimento:=VP_Procedimento;
  inherited Create(VP_Suspenso);
end;

procedure TThRecebe.Execute;
begin
 while not Terminated do
 begin
  sleep(100);
  if Assigned(fprocedimento) then
  if DComunicador.IdTCPEscuta.Connected then
  begin
   fprocedimento(DComunicador.IdTCPEscuta.Socket.ReadLn);
  end
  else
  begin
   sleep(5000);
   DComunicador.conectaescuta;
  end;
 end;
 if DComunicador.IdTCPEscuta.Connected then
 DComunicador.IdTCPEscuta.Disconnect;

end;

procedure TDComunicador.DataModuleCreate(Sender: TObject);
begin
  V_ChavesDasConexoes:=TTChaveConexao.Create;
end;

procedure TDComunicador.DataModuleDestroy(Sender: TObject);
begin
  if IdTCPSolicita.Connected then
  IdTCPSolicita.Disconnect;

  V_ChavesDasConexoes.free;
  V_ConexaoEscuta.Free;
  V_ConexaoSolicita.Free;


  if Assigned(V_ThRecebe) then
  V_ThRecebe.Terminate;

end;

procedure TDComunicador.IdTCPEscutaConnected(Sender: TObject);
begin
  V_ConexaoEscuta.Status:=csLink;
end;

procedure TDComunicador.IdTCPEscutaDisconnected(Sender: TObject);
begin
   V_ConexaoSolicita.Status:=csDesconectado;
end;

procedure TDComunicador.IdTCPServerCaixaConnect(AContext: TIdContext);
var
 TConexao: TTConexao;
begin
 TConexao:=TTConexao.Create;
 TConexao.Hora:=Now;
 TConexao.ClienteIp:=AContext.Connection.Socket.Binding.PeerIP;
 TConexao.ClientePorta:=AContext.Connection.Socket.Binding.PeerPort;
 TConexao.Status:=csLink;
 TConexao.ChaveComunicacaoIDX:=V_ChavesDasConexoes.addChave(TConexao.getChaveComunicacao);
 AContext.Data:=TConexao;
 end;


procedure TDComunicador.IdTCPServerCaixaExecute(AContext: TIdContext);
var
 VL_DadosRecebidos:String;
 VL_Comando:String;
 VL_Mensagem:TMensagem;

begin
 VL_Comando:='';
 VL_Mensagem:=TMensagem.Create;

 VL_DadosRecebidos:=AContext.Connection.Socket.ReadLn;

 if (TTConexao(AContext.Data).Status=csChaveado) or (TTConexao(AContext.Data).Status=csLogado) then
 VL_DadosRecebidos:=Copy(VL_DadosRecebidos,1,5)+TTConexao(AContext.Data).Aes.DecryptString(Copy(VL_DadosRecebidos,6,MaxInt));

 if VL_Mensagem.CarregaTags(VL_DadosRecebidos)<>0 then
 begin
  AContext.Connection.Disconnect;
  Exit;
 end;

 if VL_Mensagem.GetComando(VL_Comando)<>0 then
 begin
  AContext.Connection.Disconnect;
  Exit;
 end;

 case VL_Comando of
   '0001': comando0001(VL_Mensagem,AContext);
   '0021': comando0021(VL_Mensagem,AContext);
   '000A': comando000A(VL_Mensagem,AContext);
 else ;
   AContext.Connection.Disconnect;
 end;
 VL_Mensagem.Free;
end;

procedure TDComunicador.IdTCPServerLibConnect(AContext: TIdContext);
var
 TConexao: TTConexao;
begin
 TConexao:=TTConexao.Create;
 TConexao.Hora:=Now;
 TConexao.ClienteIp:=AContext.Connection.Socket.Binding.PeerIP;
 TConexao.ClientePorta:=AContext.Connection.Socket.Binding.PeerPort;
 AContext.Data:=TConexao;
 end;

procedure TDComunicador.IdTCPServerLibExecute(AContext: TIdContext);
begin
    AContext.Connection.Socket.ReadByte;
end;

procedure TDComunicador.IdTCPSolicitaConnected(Sender: TObject);
begin
   V_ConexaoSolicita.Status:=csLink;
end;

procedure TDComunicador.IdTCPSolicitaDisconnected(Sender: TObject);
begin
   V_ConexaoSolicita.Status:=csDesconectado;
end;

function TDComunicador.TransmiteSolicitacaoCliente(var VO_Dados:TMensagem;var VO_Retorno:TMensagem; VP_Procedimento:TRecebe):Integer;
var
 VL_DadosCriptografado:String;
 VL_Dados:String;
begin
  Result:=0;
  VL_Dados:='';
  try
  if (V_ConexaoSolicita.Status<>csChaveado) and (V_ConexaoSolicita.Status<>csLogado) then
  begin
       Result:=DComunicador.ConectarSolicitacao;
       if Result<>0 then
       Exit;
  end;
  Result:=VO_Dados.TagToStr(VL_Dados);
  if Result<>0 then
  Exit;
  VL_DadosCriptografado:=Copy(VL_Dados,1,5)+DComunicador.V_ConexaoSolicita.Aes.EncryptString(Copy(VL_Dados,6,MaxInt));
  IdTCPSolicita.Socket.WriteLn(VL_DadosCriptografado);
  VL_Dados:=IdTCPSolicita.Socket.ReadLn;
  VL_Dados:=Copy(VL_Dados,1,5)+DComunicador.V_ConexaoSolicita.Aes.DecryptString(Copy(VL_Dados,6,MaxInt));
  VO_Retorno.CarregaTags(VL_Dados);
  if Assigned(VP_Procedimento) then
  VP_Procedimento(VL_Dados);
  except
    Result:=24;
  end;
end;

procedure TDComunicador.iniciaescuta(VP_Procedimento:TRecebe);
begin
 V_ThRecebe:=TThRecebe.Create(True,VP_Procedimento);
 V_ThRecebe.Start;
end;

function TDComunicador.conectaescuta:Integer;
begin
 Result:=0;
 //try
 // IdTCPEscuta.Connect(host,porta);
 // except
 //  Result:=25;
 // end;
 //

end;

function TDComunicador.EnviarCliente(VL_Mensage: TMensagem; VP_AContext: TIdContext): Integer;
var
 VL_Dados:String;
begin
VL_Dados:='';
VL_Mensage.TagToStr(VL_Dados);

VL_Dados:= Copy(VL_Dados,1,5)+TTConexao(VP_AContext.Data).Aes.EncryptString(Copy(VL_Dados,6,MaxInt));

VP_AContext.Connection.Socket.WriteLn(VL_Dados);

end;

function TDComunicador.comando0021(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;
var
 VL_Dados:String;
 VL_ExpoentePublico,VL_ModuloPublico:String;
 VL_TChaves:TTChaveComunicacao;
 VL_Mensage:TMensagem;

begin
VL_Mensage:=TMensagem.Create;
VL_Dados:='';
VL_TChaves.ID:=0;
VL_TChaves.ChaveComunicacao:='';
VL_ModuloPublico:='';
VL_ExpoentePublico:='';
try
  VP_Mensagem.GetTag('0023',VL_Dados);
  Result:=33;
  if TTConexao(VP_AContext.Data).Status=csDesconectado then
  Exit;
  if VL_Dados<>'' then
  begin
    VP_Mensagem.GetTag('0022',VL_TChaves.ID);
    VL_TChaves:= V_ChavesDasConexoes.getChave((VL_TChaves.ID));
    if VL_TChaves.ID>0 then
    begin
     TTConexao(VP_AContext.Data).setChaveComunicacao(VL_TChaves.ChaveComunicacao);
     try
       if TTConexao(VP_AContext.Data).Aes.DecryptString(VL_Dados)='OK' then
       begin
        VL_Mensage.AddComando('0024','');
        VL_Mensage.TagToStr(VL_Dados);
        TTConexao(VP_AContext.Data).Status:=csChaveado;
        VP_AContext.Connection.Socket.WriteLn(VL_Dados);
        Exit;
       end;
     except

     end;
    end;
    VP_Mensagem.GetTag('0008',VL_ModuloPublico);
    VP_Mensagem.GetTag('0027',VL_ExpoentePublico);
    if VL_ExpoentePublico='' then
    begin
     VL_Mensage.AddComando('0026','31');
     VL_Mensage.TagToStr(VL_Dados);
     VP_AContext.Connection.Socket.WriteLn(VL_Dados);
     Exit;
    end;
   end;
    VL_Mensage.limpar;
    VL_Mensage.AddComando('0025','');
    VP_Mensagem.GetTag('0008',VL_ModuloPublico);
    VP_Mensagem.GetTag('0027',VL_ExpoentePublico);

    TTConexao(VP_AContext.Data).setModuloPublico(VL_ModuloPublico);
    TTConexao(VP_AContext.Data).setExpoentePublico(VL_ExpoentePublico);

    VL_TChaves.ChaveComunicacao:=TTConexao(VP_AContext.Data).getChaveComunicacao;
    VL_TChaves.ID:=TTConexao(VP_AContext.Data).ChaveComunicacaoIDX;

    VL_Dados:=TTConexao(VP_AContext.Data).Rsa.EncryptString(VL_TChaves.ChaveComunicacao);

    VL_Mensage.AddTag('0009',VL_Dados);
    VL_Mensage.AddTag('0022',VL_TChaves.ID);
    VL_Mensage.AddTag('0008',TTConexao(VP_AContext.Data).ModuloPublico);
    VL_Mensage.AddTag('0027',TTConexao(VP_AContext.Data).ExpoentePublico);
    VL_Mensage.AddTag('0023',TTConexao(VP_AContext.Data).Aes.EncryptString('OK'));

    VL_Mensage.TagToStr(VL_Dados);
    TTConexao(VP_AContext.Data).Status:=csChaveado;
    VP_AContext.Connection.Socket.WriteLn(VL_Dados);
    Result:=0;


finally
  VL_Mensage.Free;
end;

end;

function TDComunicador.comando0001(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;
var
 VL_Dados:String;
 VL_ChaveTerminal:String;
 VL_Mensagem:TMensagem;

begin
Result:=0;
VL_Mensagem:=TMensagem.Create;
VL_Dados:='';
VL_ChaveTerminal:='';
try


  VP_Mensagem.GetTag('0002',VL_ChaveTerminal);

  if VL_ChaveTerminal='123456' then
  VL_Mensagem.AddComando('0028','OK')
  else
  VL_Mensagem.AddComando('0029','OK');

  EnviarCliente(VL_Mensagem,VP_AContext);


finally
  VL_Mensagem.Free;
end;


end;

function TDComunicador.comando000A(VP_Mensagem: TMensagem;VP_AContext:TIdContext): Integer;
var
 VL_Dados:String;

begin
Result:=0;
VL_Dados:='';

  VP_Mensagem.TagToStr(VL_Dados);

  EnviarCliente(VP_Mensagem,VP_AContext);



end;


end.

