#!/usr/bin/perl
#
# Script para realizacao de backups com destino ao Amazon S3


use Switch;
use List::Util qw(shuffle);


# Recebendo o tipo de funcao a ser executado - FULL | DIFF
my $BackupType = @ARGV['0']; 

# Todos os servidores que devem ser sincronizados com a amazon devem constar no array abaixo
my @servidores = ("CHAT","CORDILHEIRA","DASHBOARDS","DNS01","DNS21","FINANCEIRO","FIREWALL","GW056","GW059","GW111","GW114","GW212","GW214","GW215","GW216","GWE-APP-MAIN","HSBC","OCSINVENTORY","OPENSIPS01","PRODUCAO","PROJETOS","SAO-HUGO","SFTP","SIPPROXY01","SISTEMAS","SUITECRM","SUTECRM","VHOST01-DMZ","VOICEPR","VOICERPR","ZABBIX","ZIMBRA");

# Declarando variaveis referente aos caminhos dos diretorios

my $BackupDiffDir = '/backup/RSYNC_DIFFS';
my $BackupFullDir = '/backup/RSYNC';
my $logDir = '/var/log/wsamazon';
my $programLogFile = 'wsamazon.log';
my $hostname = 'backup2';

if(!-d $logDir){
	die("Diretorio de log [ $logDir ] nao encontrado");
}

switch ($BackupType) {
	case 'FULL' { execFull(@servidores); }
	case 'DIFF' { execDiff(@servidores); }
	else	    { print "Deve ser utilizado FULL ou DIFF como argumento\n"; }
}


# Funcoes


# Funcao para pegar datas anteriores para uso pelo modulo de DIFF
sub getYeasterday{
	my $numDays = ($_[0] * 24);
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( ( time() - ( $numDays * 60 * 60 ) ) );
	$mon = $mon + 1;
	if($mon < 10){ $mon = "0" . $mon; }
	if($mday < 10){ $mday = "0" . $mday; }
        return ( ($year +1900), $mon, $mday );
}


# Funcao para execucao de Backup FULL
sub execFull {
	
	# Iniciando loop sobre variavel de servidores ( servidores randomizados )
	@shuffleServers = shuffle(@_);
	foreach $server (@shuffleServers) {
	
		# Gerando informacao de data para utilizacao em log
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		if($mon < 10){ $mon = "0" . $mon; }
		if($mday < 10){ $mday = "0" . $mday; }


		my $ModuleLogFile = $logDir . '/' . $server . "-" . ($year + 1900) . $mon . $mday;
		
		print "Servidor: $server \n";
		print "Log: $ModuleLogFile\n";
		print "Iniciando em: $hour:$min\n";

		# Redirecionando sainda por handle 
		open (my $STDOLD, '>&', STDOUT);
		open (my $STDOLDERR, '>&', STDERR);
		open(STDOUT, ">>$ModuleLogFile");
		open(STDERR, ">&STDOUT");


		# Iniciando sincronia
		print "Comando Executado: s3cmd -v sync /backup/RSYNC/$server/ s3://backup-softmarketing/$hostname/RSYNC/$server/\n";
		system("s3cmd -v sync /backup/RSYNC/$server/ s3://backup-softmarketing/$hostname/RSYNC/$server/");

		# Fechando redirecioando do handle

		open(STDOUT, '>&', $STDOLD);
		open(STDERR, '>&', $STDOLDERR);


		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		print "Finalizdo em: $hour:$min\n";


	}	
	
	


}

sub execDiff {
	# Iniciando loop sobre variavel de servidores ( servidores randomizados )
        @shuffleServers = shuffle(@_);
        foreach $server (@shuffleServers) {
		# Pegando a data de DIFF de 3 dias atras para copiar
		my ($o_year, $o_month, $o_day) = getYeasterday(3);
		if( -e "$BackupDiffDir/$o_year/$o_month/$o_day/$server" ){

			 # Gerando informacao de data para utilizacao em log
                	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
                	if($mon < 10){ $mon = "0" . $mon; }
                	if($mday < 10){ $mday = "0" . $mday; }


                	my $ModuleLogFile = $logDir . '/' . $server . "-DIFF-" . ($year + 1900) . $mon . $mday;
		
			print "Servidor: $server \n";
                	print "Log: $ModuleLogFile\n";
                	print "Iniciando em: $hour:$min\n";

			# iniciando a sincronia
			print "Comando Executado: s3cmd -v sync $BackupDiffDir/$o_year/$o_month/$o_day/$server/ s3://backup-softmarketing/$hostname/RSYNC_DIFFS/$o_year/$o_month/$o_day/$server/\n";

			# Redirecionando sainda por handle 
                	open (my $STDOLD, '>&', STDOUT);
                	open (my $STDOLDERR, '>&', STDERR);
                	open(STDOUT, ">>$ModuleLogFile");
                	open(STDERR, ">&STDOUT");

	
			system("s3cmd -v sync $BackupDiffDir/$o_year/$o_month/$o_day/$server/ s3://backup-softmarketing/$hostname/RSYNC_DIFFS/$o_year/$o_month/$o_day/$server/");


	                # Fechando redirecioando do handle

        	        open(STDOUT, '>&', $STDOLD);
               	 	open(STDERR, '>&', $STDOLDERR);


                	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
               		print "Finalizdo em: $hour:$min\n";
 
		}else{
			print "Nao existe pasta do servidor em $BackupDiffDir/$o_year/$o_month/$o_day/$server\n";
		}

	}
}

