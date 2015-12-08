unit uBureauTools;

interface

  uses tools, Windows, SysUtils, IniFiles, Classes, HTTPApp;

  const
    cMaxLayouts = 32;

  type

    tLayout = class(TObject)
      Nome: string;
      Tam: integer;
      Desc: string;
      public
        procedure Reset;
    end;

    tConfig = class(TObject)
      ArqConfig: string;
      Saida: string;
      Serv: string;
      User: string;
      Pass: string;
      Layouts: array [0 .. cMaxLayouts - 1] of tLayout;

      public
        constructor Create; overload;
        destructor Destroy; overload;
        procedure Load;
        procedure Save;
    end;

  var
    gConfig: tConfig;

  function ReplaceTag(const S, OldPattern, NewPattern: string): string;

implementation

  { tLayout }

  procedure tLayout.Reset;
    begin
      with self do
        begin
          Nome := '';
          Tam := 0;
          Desc := '';
        end;
    end;

  { tConfig }

  constructor tConfig.Create;
    var
      i: integer;
    begin
      // Execute the parent (TObject) constructor first
      inherited; // Call the parent Create method
      for i := 0 to cMaxLayouts - 1 do
        Layouts[i] := tLayout.Create;
    end;

  destructor tConfig.Destroy;
    var
      i: integer;
    begin
      inherited; // Call the parent Create method
      for i := 1 to cMaxLayouts - 1 do
        begin
          FreeAndNil(Layouts[i]);
        end;
    end;

  procedure tConfig.Load;
    var
      Ini:     TIniFile;
      xLayout: string;
      i:       integer;
      xStr:    string;
      axTStr:  TStringList;
      procedure CriaIni;
        var
          vFile: TextFile;
        begin
          AssignFile(vFile, gConfig.ArqConfig);
          try
            Rewrite(vFile);
          finally
            CloseFile(vFile);
          end;
        end;

    begin
      /// ffff      gConfig.ArqConfig := ChangeFileExt(Application.ExeName, '.INI');
      if not FileExists(gConfig.ArqConfig) then
        begin
          CriaIni;
          Load; // Recursividade pra ler padrão
          Save; // e Salvar no INI
        end;

      Ini := TIniFile.Create(gConfig.ArqConfig);
      // Ini.ReadSection('Exporta', Form1.ListBox1.Items);
      with self, Ini do
        begin
          Saida := ReadString('Impressora', 'Saida', 'LPT1');

          Serv := ReadString('Banco', 'serv', 'localhost');
          User := ReadString('Banco', 'user', 'user');
          Pass := ReadString('Banco', 'pass', 'pass');
          axTStr := TStringList.Create;
          try
            for i := 0 to cMaxLayouts - 1 do
              begin
                xLayout := 'Layout' + IntToStr(i + 1);
                Layouts[i].Nome := xLayout;
                Layouts[i].Tam := 0;
                Layouts[i].Desc := xLayout;
                try
                  // Layout: Nome, Tamanho, Descricao
                  // Ex: Tags.prn, 3, Tag de 3 colunas
                  xStr := ReadString('Layouts', xLayout, xLayout + ', 0, Layout de 3 colunas');

                  if not(ContaStr(xStr, ',') = 2) then
                    raise Exception.Create(xLayout + ' Falha na definição de parâmetros!' + #13 + 'Encontrado: ' + xStr);
                  ConverteTextoLista(xStr, axTStr, True, ','); // ',' separador de dados do campo

                  Layouts[i].Nome := axTStr.Strings[0];
                  try
                    Layouts[i].Tam := StrToInt(axTStr.Strings[1]);
                  except
                    on E: Exception do
                      raise Exception.Create(xLayout + '(Nome): ' + Layouts[i].Nome + ': definido Tamanho inválido.' + #13 + E.Message);
                    // MsgErro(xLayout + '(Nome): ' + Layouts[i].Nome + ': definido Tamanho inválido.');
                  end;
                  Layouts[i].Desc := axTStr.Strings[2];
                except
                  on E: Exception do
                    MsgErro(E.ClassName + #13 + #13 + E.Message);
                end;
              end;
          finally
            FreeAndNil(axTStr);
          end;
        end;
    end;

  procedure tConfig.Save;
    var
      Ini:  TIniFile;
      i:    integer;
      xStr: string;
    begin
      with Ini, Layouts[i] do
        begin
          Ini := TIniFile.Create(gConfig.ArqConfig);
          WriteString('Impressora', 'Saida', Saida);

          WriteString('Banco', 'serv', Serv);
          WriteString('Banco', 'user', User);
          WriteString('Banco', 'pass', Pass);

          // Limpar campos
          for i := 0 to cMaxLayouts - 1 do
            DeleteKey('Layouts', 'Layout' + IntToStr(i + 1));
          // Layout: Nome, Tamanho, Descricao
          // Ex: Tags.prn, 3, Tag de 3 colunas
          // Garatir gravar 1 Layout modelo
          WriteString('Layouts', 'Layout1', 'Layout1, 3, Layout de 3 colunas');

          for i := 0 to cMaxLayouts - 1 do
            with Layouts[i] do
              begin
                if Tam <= 0 then
                  Break;
                xStr := Nome;
                xStr := xStr + ', ' + IntToStr(Tam);
                xStr := xStr + ', ' + Desc;
                WriteString('Layouts', 'Layout' + IntToStr(i + 1), xStr);
              end;

        end;
    end;

  function ReplaceTag(const S, OldPattern, NewPattern: string): string;
    const
      FirstIndex = Low(string);
    var
      SearchStr, Patt, NewStr, xStr: string;
      OffsetS, OffsetE, i, L:        integer;

      function TamMax(tag: string; const pTam: integer = 0): integer;

        var
          tStr: TStringList;
          // xStr: string;
        begin
          tStr := TStringList.Create;
          try
            ConverteTextoLista(Copy(tag, 2, tag.Length - 2), tStr, True, ',');
            try
              Result := StrToInt(DeixaNumero(tStr.Strings[1]));
            except
              on E: Exception do
                Result := pTam;
            end;

          finally
            FreeAndNil(tStr);
          end;

        end;

    begin
      SearchStr := S;
      Patt := '<' + OldPattern; // "<" início do tag
      NewStr := S;
      Result := '';
      if SearchStr.Length <> S.Length then
        begin
          i := FirstIndex;
          L := OldPattern.Length;
          while i <= High(S) do
            begin
              // if string.Compare(S, i - FirstIndex, OldPattern, 0, L, True) = 0 then
              if string.Compare(S, i - FirstIndex, Patt, 0, L, True) = 0 then
                begin
                  Result := Result + NewPattern;
                  Inc(i, L);

                  Result := Result + S.Substring(i - FirstIndex, MaxInt);
                  Break;

                end
              else
                begin
                  Result := Result + S[i];
                  Inc(i);
                end;
            end;
        end
      else
        begin
          while SearchStr <> '' do
            begin
              OffsetS := AnsiPos(Patt, SearchStr);
              if OffsetS = 0 then
                begin
                  Result := Result + NewStr;
                  Break;
                end;

              // busca ">"  fim da tag
              xStr := Copy(NewStr, OffsetS, MaxInt);
              OffsetE := AnsiPos('>', xStr);

              Patt := Copy(NewStr, OffsetS, OffsetE);

              // Result := Result + Copy(NewStr, 1, OffsetS - 1) + NewPattern;
              Result := Result + Copy(NewStr, 1, OffsetS - 1);
              xStr := '';
              xStr := FormataStr(taCentro, NewPattern, TamMax(Patt, NewPattern.Length));
              Result := Result + xStr;

              // NewStr := Copy(NewStr, Offset + Length(OldPattern), MaxInt);
              NewStr := Copy(NewStr, OffsetS + Length(Patt), MaxInt);
              // if not(rfReplaceAll in Flags) then
              // begin
              Result := Result + NewStr;
              Break;
              // end;
              SearchStr := Copy(SearchStr, OffsetS + Length(Patt), MaxInt);
            end;
        end;
    end;

end.
