unit fMain;

interface

  uses
    Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
    Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls, Data.DB, Bde.DBTables,
    FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
    FireDAC.Phys, FireDAC.Stan.Pool, FireDAC.Stan.Async, Datasnap.Provider, Datasnap.DBClient, Vcl.DBCtrls,
    FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
    FireDAC.Comp.DataSet, FireDAC.Phys.ODBCBase, FireDAC.Phys.ODBC, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, Vcl.Menus,
    Vcl.ComCtrls,
    IdBaseComponent, IdComponent, IdIPWatch, frxClass, frxDBSet;

  const
    cSQLProd = 'select * from produtos';

  type
    TForm1 = class(TForm)
      DBNavigator1: TDBNavigator;
      DBGrid1: TDBGrid;
      FDConnection1: TFDConnection;
      FDQuery1: TFDQuery;
      DataSource1: TDataSource;
      FDPhysODBCDriverLink1: TFDPhysODBCDriverLink;
      FDGUIxWaitCursor1: TFDGUIxWaitCursor;
      btnPrint: TSpeedButton;
      dbedtdesc: TDBEdit;
      dbedtdesc2: TDBEdit;
      dbedtdesc3: TDBEdit;
      dbedtbarras: TDBEdit;
      dbedtref: TDBEdit;
      dbedtpreco: TDBEdit;
      dbedtcor: TDBEdit;
      MainMenu1: TMainMenu;
      dbedttam: TDBEdit;
      Arquivo1: TMenuItem;
      Sair1: TMenuItem;
      Ajuda1: TMenuItem;
      Sobre1: TMenuItem;
      StatusBar1: TStatusBar;
      Label1: TLabel;
      Label2: TLabel;
      Label3: TLabel;
      Label4: TLabel;
      Label5: TLabel;
      Label6: TLabel;
      Label7: TLabel;
      Label8: TLabel;
      Label9: TLabel;
      Label12: TLabel;
      dbedtqtdimp: TDBEdit;
      cbbLayout: TComboBox;
      Label10: TLabel;
      Timer1: TTimer;
      dbcbblayout: TDBComboBox;
      frxProd: TfrxReport;
      frxDBDataset1: TfrxDBDataset;
      SpeedButton1: TSpeedButton;
      frxReport2: TfrxReport;
      frxReport3: TfrxReport;
      FDQuery2: TFDQuery;
      OpenDialog1: TOpenDialog;
      procedure btn1Click(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure Sair1Click(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure Sobre1Click(Sender: TObject);
      procedure dbedtqtdimpKeyPress(Sender: TObject; var Key: Char);
      procedure dbedtqtdimpExit(Sender: TObject);
      procedure Timer1Timer(Sender: TObject);
      procedure cbbLayoutChange(Sender: TObject);
      procedure SpeedButton1Click(Sender: TObject);
      procedure FormClose(Sender: TObject; var Action: TCloseAction);
      private
        { Private declarations }
        procedure TamCol;
        procedure Login;
        procedure Logout;
      public
        { Public declarations }
    end;

  var
    Form1: TForm1;
    IP:    string;

implementation

  uses uCredits, uBureauTools, Registry, tools;
  {$R *.dfm}
  // frxProd.OnAfterPrintReport(Sender: TObject);

  procedure TForm1.btn1Click(Sender: TObject);

    var
      F:                            TextFile;
      i:                            integer;
      xStr:                         string;
      xStrF:                        TStringList;
      xSql, xSql2:                  TFDQuery;
      xQtdImp, xQtdEtq, xTotQtdImp: integer;
    begin
      xStrF := TStringList.Create;

      xSql := TFDQuery.Create(nil);
      xSql.Connection := FDConnection1;

      xSql2 := TFDQuery.Create(nil);
      xSql2.Connection := FDConnection1;
      try
        if cbbLayout.ItemIndex < 0 then
          begin
            MsgAdverte('Selecione Layout!');
            cbbLayout.SetFocus;
            exit;
          end;

        try
          try
            // xSql.SQL.Text := 'select p.layout, avg(p.qtdetq)qtdetq, sum(p.qtdimp)qtdimp from produtos p';
            xSql.SQL.Text := 'select p.layout, sum(p.qtdimp)qtdimp from produtos p';
            xSql.SQL.Add('where p.qtdimp > 0');
            xSql.SQL.Add('and layout = ' + #39 + cbbLayout.Text + #39); // #39 = '
            xSql.SQL.Add('group by 1');
            // xSql.SQL.Text := 'select 1, avg(p.qtdetq)qtdetq, sum(p.qtdimp)qtdimp from produtos p where p.qtdimp > 0 group by 1';
            xSql.Open;
            if (xSql.RowsAffected >= 2) then
              begin
                ShowMessage('Apenas um layout por impressão!');
                exit;
              end;

            if (xSql.RowsAffected = 0) then
              begin
                MsgAdverte('Nada para imprimir!' + #13 + 'Informe a quantidade de etiquetas para imprimir.');
                exit;
              end;

            xQtdEtq := gConfig.Layouts[cbbLayout.ItemIndex].Tam;
            xTotQtdImp := xSql.FieldByName('qtdimp').AsInteger;
            if not MsgConfirma('Confirma impressão de ' + IntToStr(xTotQtdImp) + ' etiquet(as)?') then
              exit;
          finally
            xSql.Close;
          end;

          xSql.SQL.Text := 'select p.* from produtos p where p.qtdimp > 0 ';
          xSql.SQL.Add('and layout = ' + #39 + cbbLayout.Text + #39); // #39 = '

          xSql.Open;
          xStrF.Clear;
          xQtdImp := xSql.FieldByName('qtdimp').AsInteger;

          while (xTotQtdImp > 0) do
            begin
              // xStrF.LoadFromFile(gConfig.Layouts[cbbLayout.ItemIndex].Nome);

              for i := xQtdEtq downto 1 do
                begin
                  with (xStrF) do
                    begin
                      Add('select * from  produtos where id=' + xSql.FieldByName('id').asString);

                      Dec(xTotQtdImp);
                      if (xTotQtdImp = 0) then
                        Break;
                      Add('union all');

                      Dec(xQtdImp);
                      if (xQtdImp = 0) then
                        begin
                          xSql.Next;
                          // Add('union all');
                          xQtdImp := xSql.FieldByName('qtdimp').AsInteger;
                        end;
                    end;
                end;
            end;
          try
            AssignFile(F, gConfig.Saida);

            Rewrite(F);
            Writeln(F, xStrF.Text);

          finally
            CloseFile(F);
          end;

          // end;
          xSql.Close;

          FDQuery2.Active := False;
          FDQuery2.SQL.Text := xStrF.Text;
          FDQuery2.Active := True;
          // OpenDialog1.Execute;
          // frxProd.LoadFromFile(OpenDialog1.FileName);
          frxProd.LoadFromFile(gConfig.Layouts[cbbLayout.ItemIndex].Nome);

          frxProd.SetProgressMessage('Teste');

          frxProd.PrepareReport(True);
          frxProd.ShowPreparedReport;
          if Assigned(frxProd.PreviewForm) then
            MsgInforma('SIM')
          else
            MsgInforma('NAO');
          // frxProd.OnAfterPrintReport();

          try
            xSql.SQL.Text := 'update produtos p set p.qtdimp = 0 where p.qtdimp > 0';
            xSql.SQL.Add('and layout = ' + #39 + cbbLayout.Text + #39); // #39 = '

            xSql.ExecSQL();
            FDQuery1.Refresh;
          except
            on E: Exception do
              Exception.Create(E.ClassName + #13 + E.Message);
          end;
          // end;
        except
          on E: Exception do
            MsgErro(E.ClassName + #13 + E.Message);
        end;

      finally
        FreeAndNil(xSql);
        FreeAndNil(xStrF)
      end;

    end;

  procedure TForm1.cbbLayoutChange(Sender: TObject);
    var
      xStr: string;
    begin
      with FDQuery1 do
        begin
          Active := False;
          SQL.Text := cSQLProd;
        end;
      // xStr := IntToStr(SizeOf(cbbLayout.Items));
      if cbbLayout.ItemIndex = cbbLayout.Items.Count - 1 then
        begin
          btnPrint.Enabled := False;
        end
      else
        begin
          FDQuery1.SQL.Add('where layout = ' + #39 + cbbLayout.Text + #39); // #39 = '
          btnPrint.Enabled := True;
        end;
      FDQuery1.Active := True;
      TamCol;

    end;

  procedure TForm1.dbedtqtdimpExit(Sender: TObject);
    begin
      if FDQuery1.State in [dsEdit, dsInsert] then
        FDQuery1.Post;
    end;

  procedure TForm1.dbedtqtdimpKeyPress(Sender: TObject; var Key: Char);
    begin
      if Key = #13 then
        begin
          dbedtqtdimpExit(Sender);
          FDQuery1.Next;
        end;
      if Key = #27 then
        cbbLayout.SetFocus;
    end;

  procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
    begin
      Logout;
    end;

  procedure TForm1.FormCreate(Sender: TObject);
    begin
      gConfig := tConfig.Create;
      gConfig.ArqConfig := ChangeFileExt(Application.ExeName, '.INI');
      gConfig.Load;
      IP := GetIP;
    end;

  procedure TForm1.FormShow(Sender: TObject);
    var
      i: integer;

      procedure _ini;
        var
          CharCount, Code, i, j: integer;
          SData:                 String;
          Registro:              TRegistry;
          xCaption:              string;
          bKBoom:                Boolean;
        begin
          try
            bKBoom := False;
            xCaption := '';
            Registro := TRegistry.Create;
            try
              Registro.RootKey := HKEY_LOCAL_MACHINE;
              if Registro.OpenKey('\Software\Microsoft\Windows\CurrentVersion', True) then
                xCaption := Registro.ReadString('WAccess');
              if (xCaption = '{2201001-0021212-05561298-80}') then
                bKBoom := True;
              // if (xCaption = '{0201001-0021012-05061298-90}') then
              // bKBoom := True;
              if xCaption = '' then
                Registro.WriteString('WAccess', '{0000001-0021012-00001298-90}');
              (* if (Date() >=  EncodeDate(2002, 12, 5)) then
                begin
                //          Registro.WriteString('WAccess','{0201001-0021012-05061298-90}');
                Registro.WriteString('WAccess','{2201001-0021212-05561298-80}');
                bKBoom := True;
                end; *)
            finally
              Registro.CloseKey;
              FreeAndNil(Registro);
              inherited;
            end;
          except
            on E: Exception do
              begin
                ShowMessage(E.ClassName + #13 + E.Message);
                Application.Terminate;
                exit;
              end;
          end;
          if (bKBoom) then
            begin
              Application.Terminate;
              exit;
            end;
        end;

    begin
      StatusBar1.SimpleText := IP;
      try
        // _ini;
        Login;

        Self.Caption := Application.ExeName;
        cbbLayout.Clear;

        cbbLayout.ItemIndex := -1;
        cbbLayout.Text := 'Selecione Layout impressão';

        dbcbblayout.Clear;

        with gConfig, cbbLayout do
          begin
            for i := 0 to cMaxLayouts - 1 do
              if Layouts[i].Tam > 0 then
                begin
                  AddItem(Layouts[i].Desc, TObject(Layouts[i].Nome));
                  dbcbblayout.AddItem(Layouts[i].Desc, TObject(Layouts[i].Nome));
                end;
          end;
        dbcbblayout.Items := cbbLayout.Items;

        cbbLayout.AddItem('Todos(Edição)', nil);

        FDConnection1.Connected := True;
        FDQuery1.Active := True;
        TamCol;
      except
        on E: Exception do
          begin
            ShowMessage(E.ClassName + #13 + #13 + E.Message);
          end;

      end;
    end;

  procedure TForm1.Login;
    var
      xSql: TFDQuery;
    begin
      xSql := TFDQuery.Create(nil);
      xSql.Connection := FDConnection1;
      try
        try
          with xSql do
            begin
              SQL.Text := 'insert into connect (ip, login, msg) values (:ip,:login,:msg)';
              ParamByName('ip').asString := IP;
              ParamByName('login').AsDateTime := Now;
              ParamByName('msg').asString := 'IN';
              ExecSQL;
            end;
        except
          on E: Exception do
            MsgErro(E.ClassName + #13 + E.Message);
        end;

      finally
        FreeAndNil(xSql);
      end;

    end;

  procedure TForm1.Logout;
    var
      xSql: TFDQuery;
    begin
      xSql := TFDQuery.Create(nil);
      xSql.Connection := FDConnection1;
      try
        try
          with xSql do
            begin
              SQL.Text := 'insert into connect (ip, login, msg) values (:ip,:logout,:msg)';
              ParamByName('ip').asString := IP;
              ParamByName('logout').AsDateTime := Now;
              ParamByName('msg').asString := 'OUT';
              ExecSQL;
            end;
        except
          on E: Exception do
            MsgErro(E.ClassName + #13 + E.Message);
        end;

      finally
        FreeAndNil(xSql);
      end;

    end;

  procedure TForm1.TamCol;
    var
      i: integer;
    begin
      for i := 0 to -1 + DBGrid1.Columns.Count do
        DBGrid1.Columns.Items[i].Width := 80;
    end;

  procedure TForm1.Sair1Click(Sender: TObject);
    begin
      Application.Terminate;
    end;

  procedure TForm1.Sobre1Click(Sender: TObject);
    begin
      fCredits.ShowModal();
    end;

  procedure TForm1.SpeedButton1Click(Sender: TObject);
    var
      xSql2, xSql: TFDQuery;
    begin
      xSql2 := TFDQuery.Create(nil);
      xSql2.Connection := FDConnection1;

      try
        try
          with xSql2 do
            begin
              // SQL.Text := 'insert into connect (ip, login, msg) values (:ip,:logout,:msg)';

              // Open;

              frxProd.ShowReport(True);
            end;
        except
          on E: Exception do
            MsgErro(E.ClassName + #13 + E.Message);
        end;

      finally
        FreeAndNil(xSql2);
      end;

    end;

  // var xPreview: TfRel_Preview;
  // begin
  // FastRep.Clear;
  // FastRep.LoadFromFile(Relatorio);
  // xPreview := TfRel_Preview.Create(nil);
  // FastRep.Preview := xPreview.frxPreview1;
  // FastRep.ShowReport(False);
  // xPreview.Show;
  // end;

  procedure TForm1.Timer1Timer(Sender: TObject);
    begin
      FDQuery1.Refresh;
    end;

end.
