unit pinpad;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, funcoes;
type


    TRespostaPinPad = procedure(VP_Mensagem: TMensagem);
    TPinPadErro = procedure(errCode: int16; msg: pansichar);

    { TTPinPad }

    TTPinPad = class(TThread)
        fMensagem: TMensagem;
        fRespostaPinPad: TRespostaPinPad;
    protected
        procedure Execute; override;
    public
        constructor Create(VP_CreateSuspended: boolean; VP_Mensagem: TMensagem; var VO_TRespostaPinPad: TRespostaPinPad);

    end;

    { TPinPad }
    TPinPad = class
    private
        fRespostaPinPad: TRespostaPinPad;
    public
        function CarregaLib(): integer; virtual; abstract;
        procedure SetConfig(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring); virtual; abstract;
        procedure PinPadErro(errCode: int16; msg: pansichar);
        function PinPadConectar(): integer; virtual; abstract;
        function PinPadDesconectar(): integer; virtual; abstract;
        function PinPadMensagem(VP_Mensagem: string): integer; virtual; abstract;
        function PinPadLerTarja(var VO_Tarja1, VO_Tarja2, VO_Tarja3: string; VP_TempoEspera: integer): integer; virtual; abstract;
        function PinPadLerSenha(var VO_Senha: string; VP_KW_Index: integer; VP_KW, VP_Pan: string; VP_DigMin, VP_DigMax: integer;
            VP_Mensagem: string; VP_TempoEspera: integer): integer; virtual; abstract;
    end;


    { TDPinPad }

    TDPinPad = class(TDataModule)

    private

    public

    end;

var
    D_PinPad: TDPinPad;
    F_PinPad: TPinPad;
    F_PinPaExecutando: boolean;



function CarregaPinPad(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring; var VO_RespostaPinPad: TRespostaPinPad): boolean; stdcall;
function PinPadConectar(): integer; stdcall;
function PinPadDesconectar(): integer; stdcall;
function PinPadComando(VP_Mensagem: ansistring; var VO_RespostaPinPad: TRespostaPinPad): integer; stdcall;


implementation

{$R *.lfm}

uses
    gertec_ppc930;

{ TPinPad }



function CarregaPinPad(VP_PinPad: TPinPadModelo; VP_CaminhoLib: ansistring; VP_Porta: ansistring; var VO_RespostaPinPad: TRespostaPinPad): boolean; stdcall;
begin

    if VP_PinPad = pGERTEC_PPC930 then
        F_PinPad := TGertec_ppc930.Create;
    F_PinPad.SetConfig(VP_PinPad, VP_CaminhoLib, VP_Porta);
    F_PinPad.fRespostaPinPad := VO_RespostaPinPad;
    F_PinPad.CarregaLib();
    F_PinPaExecutando := False;
    Result := True;

end;


function PinPadConectar(): integer; stdcall;
begin
    Result := F_PinPad.PinPadConectar();
    F_PinPaExecutando := False;
end;

function PinPadDesconectar: integer; stdcall;
begin
    Result := F_PinPad.PinPadDesconectar;
end;

function PinPadComando(VP_Mensagem: ansistring; var VO_RespostaPinPad: TRespostaPinPad): integer; stdcall;
var
    VL_Mensagem: TMensagem;
    VL_Dados, VL_Comando: string;
    VL_TPinPad: TTPinPad;
begin
    VL_Mensagem := TMensagem.Create;
    VL_Mensagem.CarregaTags(VP_Mensagem);
    VL_Comando := '';
    VL_Dados := '';
    VL_Mensagem.GetComando(VL_Comando, VL_Dados);
    case VL_Comando of
        '0047':
        begin
            F_PinPad.PinPadMensagem(VL_Dados);
        end;
        '0048':
        begin
            VL_TPinPad := TTPinPad.Create(True, VL_Mensagem, VO_RespostaPinPad);
            VL_TPinPad.Start;
        end
        else
        begin

        end;
    end;
    Result := 0;
end;

{ TTPinPad }

procedure TTPinPad.Execute;
var
    VL_Comando, VL_Dados: string;
    VL_Tk1, VL_Tk2, VL_Tk3: string;
    VL_Retorno: integer;
begin
    VL_Dados := '';
    VL_Comando := '';
    VL_Tk1 := '';
    VL_Tk2 := '';
    VL_Tk3 := '';
    VL_Retorno := 0;
    fMensagem.GetComando(VL_Comando, VL_Dados);
    if VL_Comando = '0048' then     //ler tarja magnetica
    begin
        while True do
        begin
            if VL_Dados = '0' then
            begin
                F_PinPad.PinPadMensagem(' Passe o cartao');
                VL_Retorno := F_PinPad.PinPadLerTarja(VL_Tk1, VL_Tk2, VL_Tk3, fMensagem.GetTagAsInteger('0051'));
                if VL_Retorno <> 0 then
                begin
                    fMensagem.AddComando('0049', IntToStr(VL_Retorno));
                    fRespostaPinPad(fMensagem);
                    F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                    sleep(2000);
                    F_PinPad.PinPadMensagem('    OpenTef    ');
                    Exit;
                end;

                fMensagem.AddComando('0052', VL_Comando);
                fMensagem.AddTag('004D', VL_Retorno);
                fMensagem.AddTag('004E', VL_Tk1);
                fMensagem.AddTag('004F', VL_Tk2);
                fMensagem.AddTag('0050', VL_Tk3);
                fRespostaPinPad(fMensagem);
                F_PinPad.PinPadMensagem('    OpenTef    ');
                Exit;
            end
            else
            begin
                fMensagem.AddComando('004D', '51');
                fRespostaPinPad(fMensagem);
                Exit;
            end;
        end;
    end;
    if VL_Comando = '005A' then     //ler tarja magnetica
    begin
        while True do
        begin
            VL_Retorno := F_PinPad.PinPadLerSenha(VL_Dados,fMensagem.GetTagAsInteger('005B'),fMensagem.GetTagAsAstring('005F'),fMensagem.GetTagAsAstring('0062'),fMensagem.GetTagAsInteger('005D'),fMensagem.GetTagAsInteger('005E'),fMensagem.GetTagAsAstring('005C'),fMensagem.GetTagAsInteger('0051'));
                if VL_Retorno <> 0 then
                begin
                    fMensagem.AddComando('0049', IntToStr(VL_Retorno));
                    fRespostaPinPad(fMensagem);
                    F_PinPad.PinPadMensagem('    Operacao       cancelada    ');
                    sleep(2000);
                    F_PinPad.PinPadMensagem('    OpenTef    ');
                    Exit;
                end;

                fMensagem.AddComando('0052', VL_Comando);
                fMensagem.AddTag('004D', VL_Retorno);
                fMensagem.AddTag('0060', VL_Dados);
                fRespostaPinPad(fMensagem);
                F_PinPad.PinPadMensagem('    OpenTef    ');
                Exit;
            end;
        end;
    end;

    F_PinPad.PinPadMensagem(VL_Dados);
end;

constructor TTPinPad.Create(VP_CreateSuspended: boolean; VP_Mensagem: TMensagem; var VO_TRespostaPinPad: TRespostaPinPad);
begin
    fMensagem := VP_Mensagem;
    fRespostaPinPad := VO_TRespostaPinPad;
    FreeOnTerminate := True;
    inherited Create(VP_CreateSuspended);
end;

procedure TPinPad.PinPadErro(errCode: int16; msg: pansichar);
var
    VL_Mensagem: TMensagem;
begin
    VL_Mensagem := TMensagem.Create;
    try
        VL_Mensagem.AddComando('0049', IntToStr(errCode));
        VL_Mensagem.AddTag('004A', msg);
        fRespostaPinPad(VL_Mensagem);
    finally
        VL_Mensagem.Free;
    end;

end;


end.
