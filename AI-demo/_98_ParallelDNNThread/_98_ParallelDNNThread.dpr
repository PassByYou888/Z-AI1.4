program _98_ParallelDNNThread;

uses
  System.StartUpCopy,
  FMX.Forms,
  ParallelDNNThreadFrm in 'ParallelDNNThreadFrm.pas' {ParallelDNNThreadForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TParallelDNNThreadForm, ParallelDNNThreadForm);
  Application.Run;
end.
