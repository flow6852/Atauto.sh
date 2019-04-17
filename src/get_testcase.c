#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#define N 512

char *filestr(char *str, int base, char num){
	str[base]=num;
	return str;
}

int filebase(char *str){
	int i;
	for(i=0;i<strlen(str);i++){
		if('0'<=str[i]&& str[i]<='9')break;
	}
	return i;
}

char *createfname(char *ret,char *io, int i){
	strcpy(ret,io);
	ret[strlen(io)]='/';
	ret[strlen(io)+1]='A'+i-1;
	ret[strlen(io)+2]='/';
	strcpy(&ret[strlen(io)+3],io);
	ret[strlen(io)*2+3]='1';
	strcat(ret,".txt");
	return ret;
}

char *chret(char *ret){
	int i;
	for(i=0;i<strlen(ret);i++) if(strcmp(&ret[i],"\r\n")==0)strcpy(&ret[i],"\n");
	return ret;
}

void get_testcases(char *io, char *io_filename, FILE *fp){
	FILE *wfp;
	char str[N];
	int flug=0;//0 is not scanning.1 is scanning. 2 is testcases. 
	char filenum = '1';

	while(fgets(str,N,fp)!=NULL){
		if(strncmp(str,io,strlen(io))==0){
			flug=1;	
			if((wfp=fopen(filestr(io_filename,filebase(io_filename), filenum),"w"))==NULL){
				printf("%s can't open\n",filestr(io_filename,filebase(io_filename), filenum));
			}
		}
		if(flug==1){
			int i;
			for(i=0;i<strlen(str);i++){//scanning
				if(str[i] == '<' && strncmp(&str[i],"<pre",strlen("<pre"))==0){
					flug=2;
				}
				if(flug==2 && str[i] == '>' && strcmp(&str[i+1],"\r \n")!=0)strcpy(str,&str[i+1]);
			}	
		}
		if(strncmp(str,"</pre>",strlen("</pre>"))==0 && flug==2){
			flug=0;
			filenum++;
			fclose(wfp);
		}
		if(flug==2 && strlen(str)>0 && strcmp(str,"\r\n")!=0){
			fprintf(wfp,"%s",chret(str));
		}
	}
}

int main(int argc, char *argv[]){
	FILE *fp;
	char input_filename[N]="";
	char output_filename[N]="";
	

	if((fp=fopen(argv[1],"r"))==NULL) {
		printf("%s can't open\n",argv[1]);
		return 1;
	}
	
	get_testcases("<h3>入力例",createfname(input_filename,"input",atoi(argv[2])),fp);
	fclose(fp);

	if((fp=fopen(argv[1],"r"))==NULL) {
		printf("%s can't open\n",argv[1]);
		return 1;
	}
	get_testcases("<h3>出力例",createfname(output_filename,"output",atoi(argv[2])),fp);
	fclose(fp);

	return 0;
}
