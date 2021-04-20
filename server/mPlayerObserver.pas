unit mPlayerObserver;

interface

uses Classes,ComCtrls,SysUtils;

type
  TPlayerObserver = class
    procedure update;     virtual; abstract;
  end;

type
  TSubject = class
    protected
      FMyObservers : TList;
      procedure callObservers;
    public
      procedure addObserver(Observer:TPlayerObserver);
      procedure delObserver(Observer:TPlayerObserver);

      constructor Create;
      destructor  Destroy;  override;
  end;

type
  TClientListObserver = class (TPlayerObserver)
    private
      FMySubject : TSubject;
      FMyItem : TListItem;
    public
      procedure update;    override;
      constructor Create(Subject : TSubject; Item : TListItem);
      destructor Destroy;   override;
  end;

type
  TAnswerListObserver = class (TPlayerObserver)
    private
      FMyListView : TListView;
      FMySubject : TSubject;
      FMyRow : TListItem;
    public
      constructor Create(Subject : TSubject; ListView : TListView);
      destructor Destroy;  override;
      procedure update; override;
end;

type
  TScoreBoardObserver = class (TPlayerObserver)
    private
      FMySubject : TSubject;
      FMyRow : TListItem;
    public
      constructor Create(Subject : TSubject; Row : TListItem);
      destructor Destroy;  override;
      procedure update; override;
end;

implementation

uses mPlayer;

procedure TSubject.addObserver(Observer: TPlayerObserver);
begin
  if FMyObservers.IndexOf(Pointer(Observer)) < 0 then
    FMyObservers.Add(Pointer(Observer));
end;

procedure TSubject.delObserver(Observer: TPlayerObserver);
begin
  FMyObservers.Delete(FMyObservers.IndexOf(Pointer(Observer)));
end;

procedure TSubject.callObservers;
  var
    i:integer;
begin
  for i := 0 to FMyObservers.Count - 1 do
    TPlayerObserver(FMyObservers.Items[i]).update;
end;

constructor TSubject.Create;
begin
  FMyObservers := TList.Create;
end;

destructor TSubject.Destroy;
begin
  FMyObservers.Clear;
  FMyObservers.Destroy;
end;




constructor TClientListObserver.Create(Subject : TSubject; Item : TListItem);
begin
  inherited create;
  FMySubject := Subject;
  FMyItem := Item;
end;

procedure TClientListObserver.update;
begin
  FMyItem.Caption := TPlayer(FMySubject).getName;
end;

destructor TClientListObserver.Destroy;
begin
  inherited destroy;
end;


constructor TAnswerListObserver.Create(Subject : TSubject; Listview : TListView);
begin
  inherited create;
  FMySubject := Subject;
  FMyListView := Listview;
end;

procedure TAnswerListObserver.update;
begin
  //is there an answer for the Player??
  if (TPlayer(FMySubject).getAnswer <> '') then //create a row
    begin
      if FMyRow = nil then
        begin
          FMyRow := FMyListView.Items.Add;    //create new row
          FMyRow.SubItems.Add(TPlayer(FmySubject).getAnswer); //add a subitem for the answer
          FMyRow.Data := Pointer(TPlayer(FMySubject)); //leave a link to the player container
                                                //the client remove function needs that to identify
        end
      else
        FMyRow.SubItems.Strings[0] := TPlayer(FMySubject).getAnswer;
      FMyRow.Caption := TPlayer(FMySubject).getName;      //set the row caption to the playername
    end
  else if (FMyRow <> nil) then //delete the row
    begin
      FMyListView.Items.Delete(FMyRow.Index);
      FMyRow := nil;
    end;
end;

destructor TAnswerListObserver.Destroy;
begin
  inherited destroy;
end;


constructor TScoreboardObserver.Create(Subject : TSubject; Row : TListitem);
begin
  inherited create;
  FMySubject := Subject;
  FMyRow     := Row;
end;

procedure TScoreboardObserver.update;
begin
  if FMyRow <> nil then
    begin
      FMyRow.Caption := TPlayer(FMySubject).getName;
      FMyRow.SubItems.Strings[0] := IntToStr(TPlayer(FMySubject).getPoints);
      FMyRow.SubItems.Strings[1] := IntToStr(TPlayer(FMySubject).getPercentage);
    end;
end;

destructor TScoreboardObserver.Destroy;
begin
  inherited destroy;
end;


end.
