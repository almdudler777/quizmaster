unit mPrintUtils;

interface

uses
  Windows, SysUtils, Classes, Graphics, Dialogs, ComCtrls, Printers;

procedure PrintListview(oListView: TListView; PrintDialog: TPrintDialog;
  lvTitel: Ansistring);

implementation

procedure PrintListview(oListView: TListView; PrintDialog: TPrintDialog;
lvTitel: AnsiString);
var
  pWidth, pHeight, i: Integer;
  v, h: Real;
  CurItem, iColumnCount: Integer;
  //aCols: array[0..50] of Integer; // Delphi 3
  aCols: array of Integer; // Delphi 5
  iTotColsWidth, iInnerWidth, TopMarg, LinesOnPage, CurLine, TekstHeight, CurCol: Integer;
  CurRect: TRect;
  CurStr: AnsiString;
  CurLeft, NumPages, TmpPos: Integer;

begin
  if PrintDialog.Execute then
  begin
    iColumnCount := oListview.Columns.Count;
    SetLength(aCols, iColumnCount + 1); // + 1 nodig ??? Delphi 5
    Printer.Title := 'Quizmaster_Scoreprint';
    Printer.Copies := PrintDialog.Copies;
    Printer.Orientation := poPortrait;
    Printer.BeginDoc;
    pHeight := Printer.PageHeight;
    pWidth := Printer.PageWidth;

    v := (pHeight + (2 * GetDeviceCaps(Printer.Handle,PHYSICALOFFSETY))) / (29.7 * 0.95);
    //0.95 is a strange correction factor on the clients printer
    h := (pWidth + (2 * GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX))) / 21;

    // calculate total width
    iTotColsWidth := 0;
    for i := 0 to iColumnCount - 1 do
      iTotColsWidth := iTotColsWidth + oListView.Columns[i].Width;

    // calculate space between lMargin and rMargin
    aCols[0] := Round(1.5 * h); //left margin ?
    aCols[iColumnCount + 0] := pWidth - Round(1.5 * h); //rigth margin ?
    iInnerWidth := aCols[iColumnCount + 0] - aCols[0]; // space between margins ?

    //calculate start of each column
    for i := 0 to iColumnCount - 1 do
      aCols[i + 1] := aCols[i] + Round(oListView.Columns[i].Width / iTotColsWidth * iInnerWidth);
    TopMarg := Round(2.5 * v);
    with Printer.Canvas do
    begin
      Font.Size := 10;
      Font.Style := [];
      Font.Name := 'Times New Roman';
      Font.Color := RGB(0, 0, 0);
      TekstHeight := Printer.Canvas.TextHeight('dummy');
      LinesOnPage := Round((PHeight - (5 * v)) / TekstHeight);
      NumPages := 1;

      // gather number of pages to print
      while (NumPages * LinesOnPage) < oListView.Items.Count do
        inc(NumPages);
      // start
      CurLine := 0;
      for CurItem := 0 to oListView.Items.Count - 1 do
      begin
        if (CurLine > LinesOnPage) or (CurLine = 0) then
        begin
          if (CurLine > LinesOnPage) then Printer.NewPage;
          CurLine := 1;
          if Printer.PageNumber = NumPages then
          begin
            MoveTo(aCols[1], topMarg);
            for i := 1 to iColumnCount - 1 do
            begin
              LineTo(aCols[i], TopMarg + (TekstHeight * (oListView.Items.Count - CurItem + 2)));
              MoveTo(aCols[i + 1], topMarg);
            end;
          end
          else
          begin
            // draw vertical lines between data
            for i := 1 to iColumnCount - 1 do
            begin
              MoveTo(aCols[i], topMarg);
              LineTo(aCols[i], TopMarg + (TekstHeight * (LinesOnPage + 1)));
            end;
          end;

          Font.Style := [fsBold];
          // print column headers
          for i := 0 to iColumnCount - 1 do
          begin       
            TextRect(Rect(aCols[i] + Round(0.1 * h), TopMarg - Round(0.1 * v), aCols[i + 1] - Round(0.1 * h)
              , TopMarg + TekstHeight - Round(0.1 * v)), ((aCols[i + 1]- aCols[i]) div 2) +
              aCols[i] - (TextWidth(oListview.Columns.Items[i].Caption)div 2),
              TopMarg - Round(0.1 * v), oListview.Columns.Items[i].Caption);
            //showmessage('print kolom: '+IntToStr(i));
          end;

          // draw horizontal line beneath column headers
          MoveTo(aCols[0] - Round(0.1 * h), TopMarg + TekstHeight - Round(0.05 * v));
          LineTo(aCols[iColumnCount] + Round(0.1 * h), TopMarg + TekstHeight - Round(0.05 * v));

          // print date and page number
          Font.Size := 8;
          Font.Style := [];
          TmpPos := (TextWidth('Date: ' + DateToStr(Date) + ' Page: ' +
            IntToStr(Printer.PageNumber) + ' / ' + IntToStr(NumPages))) div 2;

          TmpPos := PWidth - Round(1.5 * h) - (TmpPos * 2);

          Font.Size := 8;
          Font.Style := [];
          TextOut(TmpPos, Round(0.5 * v), 'Date: ' + DateToStr(Date) +
            ' Page: ' + IntToStr(Printer.PageNumber) + ' / ' + IntToStr(NumPages));

          // print report title
          Font.Size := 18;
          if TmpPos < ((PWidth + TextWidth(lvTitel)) div 2 + Round(0.75 * h)) then
            TextOut((PWidth - TextWidth(lvTitel)) div 2, Round(1 * v),lvTitel)
          else
            TextOut(Round(3 * h), Round(1 * v), lvTitel);

          Font.Size := 10;
          Font.Style := [];
        end;

        CurRect.Top := TopMarg + (CurLine * TekstHeight);
        CurRect.Bottom := TopMarg + ((CurLine + 1) * TekstHeight);

        // print contents of Listview
        for CurCol := -1 to iColumnCount - 2 do
        begin
          CurRect.Left := aCols[CurCol + 1] + Round(0.1 * h);
          CurRect.Right := aCols[CurCol + 2] - Round(0.1 * h);
          try
            if CurCol = -1 then
              CurStr := oListView.Items[CurItem].Caption
            else
              CurStr := oListView.Items[CurItem].SubItems[CurCol];
          except
            CurStr := '';
          end;
          CurLeft := CurRect.Left; // align left side
          // write string in TextRect
          TextRect(CurRect, CurLeft, CurRect.Top, CurStr);
        end;
        Inc(CurLine);
      end;
    end;
    Printer.EndDoc;
  end;
end;


end.
