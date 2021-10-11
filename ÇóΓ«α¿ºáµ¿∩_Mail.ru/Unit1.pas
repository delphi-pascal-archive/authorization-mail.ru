unit Unit1;

// LogIn to Mail.ru
// Copyright (C) 2010, Igor Katrich.
// Email: igor.katrich@hotmail.com

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdCookieManager, idCookie, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, StdCtrls, ComCtrls, ExtCtrls, JPEG, XPMan,
  IdAntiFreezeBase, IdAntiFreeze;

type
  TForm1 = class(TForm)
    IdHTTP1: TIdHTTP;
    IdCookieManager1: TIdCookieManager;
    Button1: TButton;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    XPManifest1: TXPManifest;
    Label2: TLabel;
    IdAntiFreeze1: TIdAntiFreeze;
    Shape1: TShape;
    Label3: TLabel;
    Image3: TImage;
    Label4: TLabel;
    Label5: TLabel;
    Bevel1: TBevel;
    Image4: TImage;
    Label6: TLabel;
    Edit1: TEdit;
    Label7: TLabel;
    Edit2: TEdit;
    ComboBox1: TComboBox;
    Button2: TButton;
    Button3: TButton;
    Label8: TLabel;
    Label9: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure IdCookieManager1NewCookie(ASender: TObject;
      ACookie: TIdCookieRFC2109; var VAccept: Boolean);
    procedure Button3Click(Sender: TObject);
    procedure IdHTTP1Connected(Sender: TObject);
    procedure IdHTTP1Disconnected(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetDataPage;
  end;

var
  Form1: TForm1;
  FConnected: Boolean;

implementation

{$R *.dfm}

function Pars(TextIn, Text, TextOut: string): string;
var
  TempStr: string;
begin
  Result := '';
  TempStr := Text;
  TempStr := Copy(TempStr, Pos(TextIn, TempStr) +7, Length(TempStr));
  Delete(TempStr, Pos(TextOut, TempStr), Length(TempStr));
  Result := TempStr;
end;

function ValidText(URL,Text: string): boolean;
var
  Str, Send : string;
  P : integer;
begin
  Str := Text;
  Send := Form1.IdHTTP1.Get(URL);
  P  := Pos(Str, Send);
  if P > 0 then
   result := true
  else
   result := false;
end;

function GetImageJpeg(IdHTTP: TIdHTTP; URL: string; DrawToImage: TImage): TJpegImage;
var
  MemoryStream: TMemoryStream;
  Img: TJpegImage;
begin
  MemoryStream := TMemoryStream.Create;
  Img := TJpegImage.Create;
  try
    IdHTTP.Get(URL, MemoryStream);
    MemoryStream.Position := 0;
    Img.LoadFromStream(MemoryStream);
    DrawToImage.Picture.Graphic := Img;
    DrawToImage.Repaint;
  finally
    MemoryStream.Free;
    Result := Img;
    Img.Free;
  end;
end;

function MailLogIn(Login,Password: string): boolean;
var
  PostData: TStringList;
  PageData: TStringList;
  Domain: string;
begin
  result := false;
  PostData := TStringList.Create;
  PageData := TStringList.Create;
  try
    // Set settings
    Form1.IdHTTP1.Request.Host := 'http://mail.ru';
    Form1.IdHTTP1.Request.UserAgent := 'Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12';
    Form1.IdHTTP1.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    Form1.IdHTTP1.Request.AcceptLanguage := 'ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3';
    //Form1.IdHTTP1.Request.AcceptEncoding := 'gzip,deflate';
    Form1.IdHTTP1.Request.AcceptCharSet := 'windows-1251,utf-8;q=0.7,*;q=0.7';
    Form1.IdHTTP1.Request.ContentType := 'application/x-www-form-urlencoded';
    Form1.IdHTTP1.Request.ContentLength := 112;
    Form1.IdHTTP1.AllowCookies := True;
    Form1.IdHTTP1.HandleRedirects := True;
    // Send post
    PostData.Add('page=');
    PostData.Add('post=');
    PostData.Add('login_form=');
    PostData.Add('Login='+Form1.Edit1.Text);
    Domain := Form1.ComboBox1.Text;
    Delete(Domain,1,1);
    PostData.Add('Domain='+Domain);
    PostData.Add('Password='+Form1.Edit2.Text);
    Form1.IdHTTP1.Post('http://win.mail.ru/cgi-bin/auth',PostData);
    // Get My World page
    PageData.Text := Form1.IdHTTP1.Get('http://my.mail.ru/');
    if ValidText('http://my.mail.ru/','logout') then result := true;
  finally
    PostData.Free;
    PageData.Free;
  end;
end;

procedure MailLogOut;
begin
  Form1.IdHTTP1.Get('http://win.mail.ru/cgi-bin/logout');
end;

procedure TForm1.GetDataPage;
var
  PostData: TStringList;
  PageData: TStringList;
  TempStr: string;
begin
  if FConnected = true then
  begin
    PostData := TStringList.Create;
    PageData := TStringList.Create;
    try
      PageData.Text := IdHTTP1.Get('http://my.mail.ru/mail/'+Edit1.Text+'/');
      // Оценки
      if ValidText('http://my.mail.ru/mail/'+Edit1.Text+'/','оценка">') then begin
      TempStr := Pars('оценка">',PageData.Text,'</a>');
      Delete(TempStr,1,1);
      Label1.Caption := TempStr;
      end else Label1.Caption := '0';
      // Оценки +10
      if ValidText('http://my.mail.ru/mail/'+Edit1.Text+'/','оценок +10">') then begin
      TempStr := Pars('оценок +10">',PageData.Text,'</a>');
      Delete(TempStr,1,5);
      Label2.Caption := TempStr;
      end else Label2.Caption := '0';
      // Имя и Фамилия
      TempStr := Pars('Hblack"',PageData.Text,'</h1>');
      Delete(TempStr,1,1);
      Label3.Caption := TempStr;
      // Страна и город
      TempStr := Pars('<a class="mf_black mf_tdn" title="',PageData.Text,'" href');
      Delete(TempStr,1,27);
      Label4.Caption := TempStr;
      // День рождения
      if ValidText('http://my.mail.ru/mail/'+Edit1.Text+'/info','<dd>День рождения:</dd><dt>') then begin
      PageData.Text := IdHTTP1.Get('http://my.mail.ru/mail/'+Edit1.Text+'/info');
      TempStr := Pars('<dd>День рождения:</dd><dt>',PageData.Text,' (<a');
      Delete(TempStr,1,20);
      Label5.Caption := TempStr;
      TempStr := Pars('http://horo.mail.ru/zodiac/sign.html?',PageData.Text,'</a>');
      Delete(TempStr,1,50);
      Label5.Caption := Label5.Caption + ', ' + TempStr;
      TempStr := Pars('</a>), ',PageData.Text,'&nbsp;');
      Label5.Caption := Label5.Caption + ', ' + TempStr;
      TempStr := Pars(TempStr+'&nbsp;',PageData.Text,'</dt>');
      Delete(TempStr,1,1);
      Label5.Caption := Label5.Caption + ' ' + TempStr;
      end else Label5.Caption := 'Скрыто';
      // Последний визит
      PageData.Text := IdHTTP1.Get('http://my.mail.ru/mail/'+Edit1.Text+'/info');
      TempStr := Pars('<dd>Последний визит:</dd><dt>',PageData.Text,'</dt>');
      Delete(TempStr,1,22);
      Label9.Caption := 'Последний визит: '+TempStr;
      // Аватарка
      PageData.Text := IdHTTP1.Get('http://my.mail.ru/mail/'+Edit1.Text+'/');
      TempStr := Pars('http://avt.foto.mail.ru/mail/'+Edit1.Text+'/',PageData.Text,');');
      Delete(TempStr,1,23+Length(Edit1.Text));
      if ValidText('http://my.mail.ru/mail/'+Edit1.Text+'/','http://avt.foto.mail.ru/mail/'+Edit1.Text+'/'+TempStr) then begin
      GetImageJpeg(IdHTTP1,'http://avt.foto.mail.ru/mail/'+Edit1.Text+'/'+TempStr,Image2);
      end;
    finally
      PostData.Free;
      PageData.Free;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Button1.Enabled := False;
  Edit1.Enabled := False;
  Edit2.Enabled := False;
  ComboBox1.Enabled := False;
  Label8.Font.Color := $00453829;
  if MailLogIn(Edit1.Text,Edit2.Text) then
  begin
    Button1.Enabled := False;
    Edit1.Enabled := False;
    Edit2.Enabled := False;
    ComboBox1.Enabled := False;
    FConnected := True;
    GetDataPage;
    Label8.Caption := 'Статус: Вход выполнен.';
    Image4.Visible := True;
    Button3.Enabled := True;
  end else begin
    Button3.Enabled := False;
    Button1.Enabled := True;
    Edit1.Enabled := True;
    Edit2.Enabled := True;
    ComboBox1.Enabled := True;
    Label8.Font.Color := $001F22EA;
    FConnected := False;
    Image4.Visible := False;
    Label8.Caption := 'Статус: Логин или пароль не верны.';
  end;
end;

procedure TForm1.IdCookieManager1NewCookie(ASender: TObject;
  ACookie: TIdCookieRFC2109; var VAccept: Boolean);
begin
  VAccept := true;
  if ACookie.Path = '' then
   ACookie.Path := '/';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  MailLogOut;
  Button1.Enabled := True;
  Button3.Enabled := False;
  Image4.Visible := False;
  Edit1.Enabled := True;
  Edit2.Enabled := True;
  ComboBox1.Enabled := True;
  IdHTTP1.Disconnect;
end;

procedure TForm1.IdHTTP1Connected(Sender: TObject);
begin
  Label8.Caption := 'Статус: Загрузка...';
end;

procedure TForm1.IdHTTP1Disconnected(Sender: TObject);
begin
  Label8.Caption := 'Статус: Готово';
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Close;
end;

end.
