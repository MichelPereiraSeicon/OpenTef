unit def;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils;

const
    C_Versao: array  [0..2] of integer = (1, 0, 0);
    C_Programa: string = 'com_lib';
    C_Mensagem = 1;

var
    C_Debug: boolean = True;
    F_NivelLog: integer = 0;
    F_Comunicacao: pchar;
    F_Versao_Comunicacao: integer = 0;

implementation

end.
