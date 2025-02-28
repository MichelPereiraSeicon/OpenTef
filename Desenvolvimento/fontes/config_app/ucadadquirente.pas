unit ucadadquirente;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, funcoes, Graphics, Dialogs,
  ExtCtrls, Buttons, StdCtrls, rxmemds;

type

  { TFCadAdquirente }

  TFCadAdquirente = class(TForm)
    BAdicionar: TBitBtn;
    BExcluir: TBitBtn;
    BLimpar: TBitBtn;
    BModificar: TBitBtn;
    BPesquisar: TBitBtn;
    BPesquisaTag: TBitBtn;
    DSAdquirente: TDataSource;
    DSTags: TDataSource;
    ETag: TEdit;
    ETagID: TEdit;
    LTitulo: TLabel;
    MDAdquirente: TRxMemoryData;
    MDTags: TRxMemoryData;
    PBotoes: TPanel;
    PTitulo: TPanel;
    EContato: TMemo;
    EDescricao: TEdit;
    EID: TEdit;
    LContato: TLabel;
    LDescricao: TLabel;
    LID: TLabel;
    PPrincipal: TPanel;
    LTag: TLabel;
    procedure BAdicionarClick(Sender: TObject);
    procedure BExcluirClick(Sender: TObject);
    procedure BLimparClick(Sender: TObject);
    procedure BModificarClick(Sender: TObject);
    procedure BPesquisarClick(Sender: TObject);
    procedure BPesquisaTagClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function GravaRegistros(VP_Tab: string; VP_Incluir: boolean = False): boolean;
  public
    procedure LimpaTela;
    procedure CarregaCampos;
    procedure CarregarAdquirente(VP_AdquirenteID: integer);
  end;

var
  FCadAdquirente: TFCadAdquirente;

implementation

{$R *.lfm}

uses
  uinterface, uPesquisaadquirentes, uPesquisaTags;

  { TFCadAdquirente }

procedure TFCadAdquirente.BLimparClick(Sender: TObject);
begin
  LimpaTela;
end;

procedure TFCadAdquirente.BModificarClick(Sender: TObject);
var
  VL_Codigo: integer;
  VL_Retorno, VL_Tag: string;
  VL_Mensagem: TMensagem;
begin
  VL_Mensagem:=nil;
  VL_Codigo := 0;
  VL_Retorno := '';
  VL_Tag := '';

  try
    VL_Mensagem := TMensagem.Create;

    if not(FInterface.VerificaPermissao(F_TipoConfigurador)) then
       Exit;

    if MDAdquirente.Active = False then
    begin
      ShowMessage('MDAdquirente não está ativo');
      Exit;
    end;

    if length(EID.Text) = 0 then
    begin
      ShowMessage('Não existe registro selecionado para alteração');
      Exit;
    end;

     if length(ETagID.Text)=0 then
    begin
      ShowMessage(LTag.Caption + ' é um campo obrigatório, pois é o identificador do Módulo do Adquirente');
      Exit;
    end;

    if GravaRegistros('TabAdquirente', False) then
    begin
      VL_Codigo := FINTERFACE.AlterarRegistro('0082', MDAdquirente, '006F', StrToInt(EID.Text), '00DF', 'S', VL_Tag);

      if VL_Codigo <> 0 then
      begin
        ShowMessage(erro(VL_Codigo));
        finterface.Desconecta;
        exit;
      end;

      VL_Mensagem.Limpar;
      VL_Mensagem.CarregaTags(VL_Tag);
      VL_Mensagem.GetComando(VL_Retorno, VL_Tag);
      case VL_Retorno of
        '0026':
        begin
          VL_Mensagem.GetTag('0026', VL_Tag);

          ShowMessage(erro(StrToInt(VL_Tag)));

          // CarregarTabelas;
          MDAdquirente.Locate('ID', StrToInt(EID.Text), []);
          CarregaCampos;
          F_Navegar := True;
          Exit;
        end;
        else
        begin
          if VL_Tag <> 'R' then
          begin
            VL_Mensagem.GetTag('004D', VL_Tag);
            ShowMessage(erro(StrToInt(VL_Tag)));
            Exit;
          end;
          VL_Mensagem.GetTag('004D', VL_Tag);
          if VL_Tag = '0' then
            ShowMessage('Registro alterado com sucesso')
          else
          begin
            ShowMessage(erro(StrToInt(VL_Tag)));
            LimpaTela;
            Exit;
          end;
        end;
      end;
      MDAdquirente.Locate('ID', StrToInt(EID.Text),[]);
      CarregaCampos;
    end;
  finally
    VL_Mensagem.Free;
  end;
end;

procedure TFCadAdquirente.BAdicionarClick(Sender: TObject);
var
  VL_Mensagem: TMensagem;
  VL_Codigo: integer;
  VL_ID: int64;
  VL_Retorno, VL_Tag: string;
begin
  VL_Mensagem := nil;
  VL_Codigo := 0;
  VL_ID := 0;
  VL_Retorno := '';
  VL_Tag := '';

  try
    VL_Mensagem := TMensagem.Create;

    if not(FInterface.VerificaPermissao(F_TipoConfigurador)) then
       Exit;

    if MDAdquirente.Active = False then
    begin
      ShowMessage('MDAdquirente não está ativo');
      Exit;
    end;

    if length(EDescricao.Text) = 0 then
    begin
      ShowMessage(LDescricao.Caption + ' é um campo obrigatório');
      Exit;
    end;

    if (Length(EID.text)>0)and(EID.Text<>'0') then
    begin
      ShowMessage('Limpe a tela para incluir um Adquirente.');
      exit;
    end;

    if length(ETagID.Text)=0 then
    begin
      ShowMessage(LTag.Caption + ' é um campo obrigatório, pois é o identificador do Módulo do Adquirente');
      Exit;
    end;

    if GravaRegistros('TabAdquirente', True) then
    begin
      VL_Codigo := FINTERFACE.IncluirRegistro(MDAdquirente, '00DE', 'S', '0082', VL_Tag);

      if VL_Codigo <> 0 then
      begin

        ShowMessage(Erro(vl_codigo));

        if MDAdquirente.Locate('ID', 0, []) then
          MDAdquirente.Delete;

        exit;
      end;

      VL_Mensagem.Limpar;
      VL_Mensagem.CarregaTags(VL_Tag);
      VL_Mensagem.GetComando(VL_Retorno, VL_Tag);

      case VL_Retorno of
        '0026':
        begin
          VL_Mensagem.GetTag('0026', VL_Tag);

          ShowMessage(erro(StrToInt(VL_Tag)));

          if MDAdquirente.Locate('ID', 0, []) then
            MDAdquirente.Delete;

          Exit;
        end;
        '00DE':
        begin
          if VL_Tag <> 'R' then
          begin
            VL_Mensagem.GetTag('004D', VL_Tag);
            ShowMessage('ERRO: O Comando não é um retorno erro numero:' + VL_Tag);
            if MDAdquirente.Locate('ID', 0, []) then
              MDAdquirente.Delete;
            Exit;
          end;
          VL_Mensagem.GetTag('004D', VL_Tag);
          if vl_tag <> '0' then
          begin

            ShowMessage(erro(StrToInt(VL_Tag)));

            if MDAdquirente.Locate('ID', 0, []) then
              MDAdquirente.Delete;
            Exit;
          end;

          VL_Mensagem.GetTag('006F', VL_ID); //RETORNO DO ID DO ADQUIRENTE
          F_Navegar := False;

          if MDAdquirente.Locate('ID', 0, []) then
          begin
            MDAdquirente.Edit;
            MDAdquirente.FieldByName('ID').AsInteger := VL_ID;
            MDAdquirente.Post;
          end;
          F_Navegar := True;
        end;
      end;

      CarregarAdquirente(VL_ID);
      CarregaCampos;
      ShowMessage('Registro incluido com sucesso');
    end;
  finally
    VL_Mensagem.Free;
    F_Navegar := True;
  end;

end;

procedure TFCadAdquirente.BExcluirClick(Sender: TObject);
var
  VL_Codigo: integer;
  VL_Mensagem: TMensagem;
  VL_Retorno, VL_Tag: string;
  VL_ID: int64;
  VL_RDescricaoErro: PChar;
  VL_DescricaoErro: string;
begin
  VL_Codigo := 0;
  VL_ID := 0;
  VL_Retorno := '';
  VL_Tag := '';
  VL_DescricaoErro := '';
  VL_RDescricaoErro := nil;

  VL_Mensagem := TMensagem.Create;

  try

    if not(FInterface.VerificaPermissao(F_TipoConfigurador)) then
      Exit;

    if MDAdquirente.Active = False then
    begin
      ShowMessage('MDAdquirente não está ativo');
      Exit;
    end;

    if length(EID.Text) = 0 then
    begin
      ShowMessage('Não existe registro selecionado para exclusão');
      Exit;
    end;

    VL_Codigo := FINTERFACE.ExcluirRegistro('006F', StrToInt(EID.Text), '00E0', 'S', VL_Tag);

    if VL_Codigo <> 0 then
    begin
      mensagemerro(VL_Codigo, VL_RDescricaoErro);
      VL_DescricaoErro := VL_RDescricaoErro;
      F_MensagemDispose(VL_RDescricaoErro);

      ShowMessage('Erro: ' + VL_Tag + #13 + VL_DescricaoErro);

      FINTERFACE.Desconecta;

      exit;
    end;

    VL_Mensagem.Limpar;
    VL_Mensagem.CarregaTags(VL_Tag);
    VL_Mensagem.GetComando(VL_Retorno, VL_Tag);
    case VL_Retorno of
      '0026':
      begin
        VL_Mensagem.GetTag('0026', VL_ID);
        mensagemerro(VL_ID, VL_RDescricaoErro);

        VL_DescricaoErro := VL_RDescricaoErro;
        F_MensagemDispose(VL_RDescricaoErro);

        ShowMessage('ERRO: ' + IntToStr(VL_ID) + #13 + VL_DescricaoErro);
        Exit;
      end;
      '00E0':
      begin
        if VL_Tag <> 'R' then
        begin
          VL_Mensagem.GetTag('004D', VL_Tag);
          ShowMessage('ERRO: O Comando não é um retorno erro numero:' + VL_Tag);
          Exit;
        end;
        VL_Mensagem.GetTag('004D', VL_Tag);
        if vl_tag <> '0' then
        begin
          VL_Mensagem.GetTag('004D', VL_ID);
          mensagemerro(VL_ID, VL_RDescricaoErro);

          VL_DescricaoErro := VL_RDescricaoErro;
          F_MensagemDispose(VL_RDescricaoErro);

          ShowMessage('ERRO: ' + IntToStr(VL_ID) + #13 + VL_DescricaoErro);
          Exit;
        end;
        VL_Mensagem.GetTag('006F', VL_ID);
        F_Navegar := False;
        if MDAdquirente.Locate('ID', VL_ID, []) then
          MDAdquirente.Delete;
        F_Navegar := True;
      end;
    end;
    CarregaCampos;
    ShowMessage('Registro Excluido com sucesso');
    LimpaTela;
  finally
    VL_Mensagem.Free;
    F_Navegar := True;
  end;

end;

procedure TFCadAdquirente.BPesquisarClick(Sender: TObject);
var
  VL_FPesquisaAdquirente: TFPesquisaAdquirente;
begin
  if not FInterface.VerificaPermissao(F_TipoConfigurador,false,true) then
    exit;
  CarregarAdquirente(0);
  VL_FPesquisaAdquirente := TFPesquisaAdquirente.Create(Self);
  VL_FPesquisaAdquirente.F_Tabela := RxMemDataToStr(MDAdquirente);
  LimpaTela;
  VL_FPesquisaAdquirente.ShowModal;
  if VL_FPesquisaAdquirente.F_Carregado then
  begin
    CarregarAdquirente(VL_FPesquisaAdquirente.MDAdquirente.FieldByName('ID').AsInteger);
    CarregaCampos;
  end;
end;

procedure TFCadAdquirente.BPesquisaTagClick(Sender: TObject);
var
  VL_FPesquisaTag: TFTags;
begin
  if not (FInterface.VerificaPermissao(F_TipoConfigurador))then
    exit;
  VL_FPesquisaTag := TFTags.Create(Self);
  VL_FPesquisaTag.F_Tabela := RxMemDataToStr(MDTags);
  VL_FPesquisaTag.F_TagTipo := TipoTagToStr(Ord(ttMODULO));  //TIPO MODULO
  VL_FPesquisaTag.ShowModal;
  if VL_FPesquisaTag.F_Carregado then
  begin
    ETagID.Text := VL_FPesquisaTag.MDTags.FieldByName('TAG_NUMERO').AsString;
    ETag.Text := VL_FPesquisaTag.MDTags.FieldByName('DEFINICAO').AsString;
  end;
end;

procedure TFCadAdquirente.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := cafree;
end;

procedure TFCadAdquirente.FormCreate(Sender: TObject);
begin
  Width := 778;
  Height := 270;
end;

procedure TFCadAdquirente.FormShow(Sender: TObject);
begin
  //prepara a tela
  LimpaTela;
  CarregarAdquirente(0);
end;

procedure TFCadAdquirente.CarregarAdquirente(VP_AdquirenteID: integer);
var
  VL_Mensagem: TMensagem;
  VL_Tag: string;
  VL_Retorno: string;
  VL_Tabela: TRxMemoryData;
begin
  VL_Tag := '';
  VL_Retorno := '';
  VL_Mensagem:=nil;
  VL_Tabela:=nil;

  try

    VL_Tabela := TRxMemoryData.Create(nil);
    VL_Mensagem := TMensagem.Create;

    VL_Mensagem.Limpar;
    VL_Mensagem.AddComando('0070', 'S');
    VL_Mensagem.AddTag('006F', 0); //adquirente_id
    VL_Mensagem.AddTag('006E', 0); //tag_id

    VL_Mensagem.TagToStr(VL_Tag);

    if VP_AdquirenteID = 0 then
      VL_Tag := FInterface.PesquisaTabelas('0070', 'S', '006F', VP_AdquirenteID, VL_Tag)
    else
      VL_Tag := FInterface.PesquisaTabelas('0070', 'S', '006F', VP_AdquirenteID, '');

    VL_Mensagem.Limpar;
    VL_Mensagem.CarregaTags(VL_Tag);
    VL_Mensagem.GetComando(VL_Retorno, VL_Tag);

    case VL_Retorno of
      '0026':
      begin
        VL_Mensagem.GetTag('0026', VL_Tag);
        ShowMessage(Erro(strtoint(vl_tag)));
        Exit;
      end;
      '0070':
      begin
        //verifica se é um retorno
        if VL_Tag <> 'R' then
        begin
          VL_Mensagem.GetTag('004D', VL_Tag);
          ShowMessage(Erro(strtoint(vl_tag)));
          Exit;
        end;
        //TABELA ADQUIRENTE
        if VL_Mensagem.GetTag('0082', VL_Tag) = 0 then
        begin
          if MDAdquirente.Active then
            MDAdquirente.EmptyTable;
          StrToRxMemData(VL_Tag, MDAdquirente);
          MDAdquirente.Open;
          if MDAdquirente.RecordCount<1 then
             ShowMessage('Nenhum adquirente foi localizado!');
        end;
        //TABELA TAG
        if VL_Mensagem.GetTag('0081', VL_Tag) = 0 then
        begin
          if MDTags.Active then
            MDTags.EmptyTable;
          StrToRxMemData(VL_Tag, MDTags);
          MDTags.Open;
        end;
      end;
    end;
  finally
    VL_Tabela.Free;
    VL_Mensagem.Free;
  end;

end;

function TFCadAdquirente.GravaRegistros(VP_Tab: string; VP_Incluir: boolean): boolean;
var
  VL_ID: integer;
begin
  Result := False;
  F_Navegar := False;
  try
    //GRAVA ADQUIRENTE
    if VP_Tab = 'TabAdquirente' then
    begin
      if not FInterface.VerificaPermissao(F_TipoConfigurador,false,false) then
          exit;

      if VP_Incluir then
      begin
        VL_ID := 0;
        MDAdquirente.Insert
      end
      else
      begin
        VL_ID := MDAdquirente.FieldByName('ID').AsInteger;
        MDAdquirente.Edit;
      end;

      MDAdquirente.FieldByName('ID').AsInteger := VL_ID;
      MDAdquirente.FieldByName('DESCRICAO').AsString := EDescricao.Text;
      MDAdquirente.FieldByName('CONTATO').AsString := EContato.Lines.Text;
      MDAdquirente.FieldByName('TAG_NUMERO').AsString := ETagID.Text;
      MDAdquirente.FieldByName('DEFINICAO').AsString := ETag.Text;
      MDAdquirente.Post;
      Result := True;
    end;
  finally
    F_Navegar := True;
  end;

end;

procedure TFCadAdquirente.CarregaCampos;
begin
  //CARREGA OS CAMPOS
  if F_Navegar = False then
    exit;
  //CARREGA ADQUIRENTE
  EID.Text := MDAdquirente.FieldByName('ID').AsString;
  EDescricao.Text := MDAdquirente.FieldByName('DESCRICAO').AsString;
  EContato.Lines.Text := MDAdquirente.FieldByName('CONTATO').AsString;
  ETagID.Text := MDAdquirente.FieldByName('TAG_NUMERO').AsString;
  ETag.Text := MDAdquirente.FieldByName('DEFINICAO').AsString;
end;

procedure TFCadAdquirente.LimpaTela;
var
  i: integer;
begin
  with self do
  begin
    for i := 0 to ComponentCount - 1 do
    begin
      if Components[i] is TEdit then
        TEdit(Components[i]).Text := '';
      if Components[i] is TMemo then
        TMemo(Components[i]).Clear;
      if Components[i] is TRxMemoryData then
        if TRxMemoryData(Components[i]).Active then
          if TRxMemoryData(Components[i]) <> TRxMemoryData(MDTags) then
            TRxMemoryData(Components[i]).EmptyTable;
    end;
  end;
end;

end.
