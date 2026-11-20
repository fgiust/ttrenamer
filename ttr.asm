
.486
MODEL FLAT, STDCALL
locals
jumps


UNICODE=0

include w32.inc


extrn   	SHBrowseForFolder		:PROC
extrn   	SHGetPathFromIDListA		:PROC
extrn   	SetCurrentDirectoryA		:PROC
extrn   	lstrcat			:PROC
extrn   	FindFirstFileA		:PROC
extrn   	FindNextFileA			:PROC
extrn   	CreateFileA			:PROC
extrn   	MessageBoxA			:PROC
extrn   	ExitProcess			:PROC
extrn   	SetFilePointer		:PROC
extrn   	ReadFile			:PROC
extrn   	CloseHandle			:PROC
extrn   	WideCharToMultiByte		:PROC
extrn   	lstrcat			:PROC
extrn   	lstrlenA			:PROC
extrn   	lstrcmpA			:PROC
extrn   	MoveFileA			:PROC
extrn   	GetModuleHandleA		:PROC
extrn   	LoadIconA			:PROC
extrn   	Shell_NotifyIconA		:PROC
extrn   	lstrcpyA			:PROC
extrn   	DeleteFileA			:PROC
extrn   	GetTickCount			:PROC


.DATA

FileHandle			dd	0			; handle del file di caratteri aperto
ByteLetti			dd	0			; numero di byte letti da ReadFile
VariabileDueByte		dd	0			; riutilizzato in tutti i casi servano 2 byte
VariabileMonoByte		db	0			; necessario per lingua non generica
VariabileQuaByte		dd	0			; riutilizzato in tutti i casi servano 4 byte
OffNameStorageBegin		dd	0			; necessario perchè poi sommato a un altro valore
NoEnglish			dd	0			; necessario per lingua non generica
Indice				dd	0			; necessario per FindNextFile
Contatore			dd	0			; conta il numero di file rinominati

NomeCarattereWide		dd 	MAX_PATH dup(0)

FileEPath			db 	MAX_PATH dup(0)

wfd				WIN32_FIND_DATA 	<?>
bri				BROWSEINFO 		<?>
nid				NOTIFYICONDATA	<?>

SearchFor			db	"\*.ttf",0
Estensione			dd	"ftt.",0

SelezionaTitolo		db	'Choose the folder containing the fonts you wish to rename',0

NoTesto			db	"Can't read this file (file not existing or in use).",13,10
				db	"Continue with next file?",0

FineDirTableTesto		db	"FaceName not found (Name Table not found into Table Directory)",0

FineNameTableTesto		db	"FaceName not found (Full Name record not found into Name Table)",0

NotFontTesto			db	"This file is not a TrueType Font file",0

WriteTesto			db	"Error in renaming file",0

NessunTtfTesto		db	"Can't find any TrueType Font file in selected folder",0

FineTitolo			db	"TrueType Renamer - All done   ",0




NumeroFile			dd 	06h + FineTesto_ dup (0)

FineTesto			db	" files renamed",13,10,0
FineTesto_ equ ($-offset FineTesto)

FineTestoTimer		dd	04h dup (0)

FineTestoTimer2		dd	",",0,0,0,0

FineTestoSaluti		db	" seconds",13,10,13,10,"TrueType Renamer 1.00",13,10,"(c) 1998 Fabrizio Giustina",13,10,"ttrenamer@hotmail.com",0


Timer				dd	0
TimerDec			dd	0,0,0,0
IconaWorking			db	"working",0
Working			db	"Renaming TrueType font files...",0
test				db	"ttr©tëmpörå™.tmp",0

SolaLetturaTesto		db	"Selected drive is read-only! TrueType Renamer can't rename files!",0

ErroreDirectoryTesto		db	"Error! Can't reach selected folder!",0

ReadTesto			db	"Error! Can't read the file",0

Decimale		DB 10 dup (0),0


.CODE

Start:

	mov [nid.nid_cbSize], 78h				; inizializzazione dell'icona nella barra

	call    GetModuleHandleA, \	
		L 0

	mov [nid.nid_hWnd], eax

	call    LoadIconA, \
		eax, \
		OFFSET IconaWorking

	mov [nid.nid_hIcon],eax
	mov [nid.nid_uFlags],NIF_ICON + NIF_TIP

	call lstrcpyA, \
		offset nid.nid_szTip, \
		offset Working

	mov [bri.bi_pszDisplayName], offset FileEPath		; riutilizzo la stessa variabile dove verrà memorizzato il percorso completo (il nome della cartella non dovrebbe mai essere più lungo del nome completo)
	mov [bri.bi_lpszTitle], offset SelezionaTitolo
	mov [bri.bi_ulFlags], BIF_RETURNONLYFSDIRS

	Call SHBrowseForFolder, \
		offset bri

	cmp eax, 0
	je Fine

	Call SHGetPathFromIDListA, \
		eax, \
		offset FileEPath
	
	Call lstrlenA, \						; queste righe sono necessarie per togliere la \ che
		offset FileEPath					; Windows inserisce solo se si seleziona la radice
									; di un drive (COMPLIMENTI MICRO$OFT)
	dec eax							;

	cmp byte ptr offset FileEPath + eax, 5ch			;
	jne NonRadice							;

	mov byte ptr offset FileEPath + eax, 00h			;
	

NonRadice:

	Call SetCurrentDirectoryA, \
		offset FileEPath

	cmp eax, 00h
	je ErroreDirectory


	Call CreateFileA, \
		OFFSET test, \
		0, \
		NULL, \
		NULL, \
		OPEN_ALWAYS, \
		FILE_ATTRIBUTE_HIDDEN + FILE_ATTRIBUTE_TEMPORARY + FILE_FLAG_DELETE_ON_CLOSE, \
		NULL

	cmp eax, 0ffffffffh
	je SolaLettura

	call CloseHandle, \
		eax

	call lstrcat, \
		offset FileEPath, \
		offset SearchFor

	call FindFirstFileA, \
		offset FileEPath, \
		offset wfd
	
	cmp eax, 0ffffffffh
	je NessunTtf
	
	mov [Indice], eax

	call Shell_NotifyIconA, \
		NIM_ADD, \
		offset nid

	call GetTickCount
	mov [Timer], eax
	jmp Inizia

AltroFile:

	call FindNextFileA, \
		[Indice], \
		offset wfd

	cmp eax, 0			;fine dei file
	je DialogFine

Inizia:

	Call CreateFileA, \
		OFFSET wfd.cFileName, \
		GENERIC_READ, \
		NULL, \
		NULL, \
		OPEN_EXISTING, \
		FILE_ATTRIBUTE_NORMAL, \
		NULL
	
	mov [FileHandle],eax

	cmp eax, INVALID_HANDLE_VALUE	; Il File esiste?
	je NonEsiste

	call TableDirProc

	jmp AltroFile

NonEsiste:
	
	Call MessageBoxA, \
		0, \
		OFFSET NoTesto, \
		OFFSET wfd.cFileName, \
		MB_OKCANCEL+MB_ICONERROR
	
	cmp eax, IDOK
	je AltroFile

DialogFine:
	

;;;;;;;;;;;;;;;;;;;;;;;;;;; conteggio secondi;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	call GetTickCount
	sub eax, [Timer]
	mov ecx, 03e8h
	div ecx
	mov [Timer], eax

; edx resto
; ora eax contiene il numero di secondi impiegati!
	mov eax, edx
	call Hex2Dec
	mov [FineTestoTimer2]+1,eax


	mov eax, [Contatore]			; eax = Stringa
	call Hex2Dec
	mov [NumeroFile], eax


	call lstrcat, \
		offset NumeroFile, \
		offset FineTesto


	mov eax, [Timer]			; eax = Stringa
	call Hex2Dec
	mov [FineTestoTimer], eax




	call lstrcat, \
		offset FineTestoTimer, \
		offset FineTestoTimer2

	call lstrcat, \
		offset NumeroFile, \
		offset FineTestoTimer


	call lstrcat, \
		offset NumeroFile, \
		offset FineTestoSaluti

	call Shell_NotifyIconA, \
		NIM_DELETE, \
		offset nid

	Call MessageBoxA, \
		0, \
		OFFSET NumeroFile, \
		OFFSET FineTitolo, \
		MB_OK+MB_ICONINFORMATION



	Call ExitProcess

SolaLettura:

	Call MessageBoxA, \
		0, \
		OFFSET SolaLetturaTesto, \
		OFFSET FileEPath, \
		MB_OK+MB_ICONERROR

	Call ExitProcess

ErroreDirectory:

	Call MessageBoxA, \
		0, \
		OFFSET ErroreDirectoryTesto, \
		OFFSET FileEPath, \
		MB_OK+MB_ICONERROR

	Call ExitProcess


NessunTtf:

	Call MessageBoxA, \
		0, \
		OFFSET NessunTtfTesto, \
		OFFSET FileEPath, \
		MB_OK+MB_ICONERROR

Fine:
	Call ExitProcess








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TableDirProc          proc uses ebx edi esi

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 1: controlla se è un file di caratteri (o se può esserlo...)

	Call SetFilePointer, \
		[FileHandle], \
		02h, \
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileQuaByte, \		
		04h		, \
		OFFSET ByteLetti, \
		NULL

	mov ebx, [VariabileQuaByte]	
	BSWAP ebx

	cmp ebx, 00000020h
	jg NotFontFile

	mov edi, 7Ch					; posiziona all'inizio della 8° table directory (la prima in cui si può trovare il nome?)
	sub ebx, 07h					; 7 table in meno da controllare!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 2: ricerca del name tag

Riprova:

	Call SetFilePointer, \
		[FileHandle], \
		edi, \	
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileQuaByte, \
		04h		, \
		OFFSET ByteLetti, \
		NULL

	cmp [VariabileQuaByte],0656d616eh
	je Trovato
 
	add edi, 10h					;posiziona all'inizio della table index successiva
	dec ebx
	jnz Riprova

	Call MessageBoxA, \
		0, \
		OFFSET FineDirTableTesto, \
		OFFSET wfd.cFileName, \
		MB_OK+MB_ICONERROR

	Call CloseHandle, \
		[FileHandle]

	ret

NotFontFile:

	Call MessageBoxA, \
		0, \
		OFFSET NotFontTesto, \
		OFFSET wfd.cFileName, \
		MB_OK+MB_ICONERROR

	Call CloseHandle, \
		[FileHandle]

	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 3: lettura dell'offset della name table, del numero di record nella name table e dell'offset della name storage


Trovato:

	Call SetFilePointer, \
		[FileHandle], \
		04h, \	
		NULL, \
		FILE_CURRENT

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileQuaByte, \
		04h, \
		OFFSET ByteLetti, \
		NULL

	
	mov edi, [VariabileQuaByte]
	bswap edi						; EDI = offset della name table

	add edi, 03h

	Call SetFilePointer, \
		[FileHandle], \	
		edi, \	
		NULL, \
		FILE_BEGIN	

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileMonoByte, \ 
		01h		, \
		OFFSET ByteLetti, \
		NULL

	xor ebx, ebx
	mov bl, byte ptr [VariabileMonoByte]		; EBX = numero record

	Call ReadFile, \
		[FileHandle], \	
		OFFSET VariabileDueByte +2, \	
		02h, \	
		OFFSET ByteLetti, \	
		NULL

	mov edx, [VariabileDueByte]
	BSWAP edx						; EDX = offset della name storage a partire dalla name table

	add edx, edi
	sub edx, 03h
	mov [OffNameStorageBegin], edx			; EDX = offset della name storage a partire dall'inizio del file   (OffNameStorageBegin)

;_________________ EDX = offset della name storage a partire dall'inizio del file   (OffNameStorageBegin)
;_________________ EDI = offset del primo NameRecord -4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 4: ricerca del record contenente il nome in encoding Microsoft in inglese, poi in altra lingua, poi Iso o Mac in Inglese, poi quello che capita...

	add edi, 07h
	mov [NoEnglish], edi

AltroNameRecord:

	Call SetFilePointer, \
		[FileHandle], \		
		edi, \		
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \	
		OFFSET VariabileQuaByte, \	
		04h, \		
		OFFSET ByteLetti, \
		NULL	

	cmp dword ptr [VariabileQuaByte],04000904h			; Microsoft - Inglese Americano
	je FullNameTrovato
 
	add edi, 0ch								; posiziona all'inizio della table index successiva
	dec ebx
	jnz AltroNameRecord

	mov edi, [NoEnglish]
	mov bl, byte ptr [VariabileMonoByte]


NoEnglishNameRecord:

	Call SetFilePointer, \
		[FileHandle], \		
		edi, \		
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \	
		OFFSET VariabileQuaByte, \	
		04h, \		
		OFFSET ByteLetti, \
		NULL	

	cmp byte ptr [VariabileQuaByte],04h			; per file CON lingua specifica
	je FullNameEQuasiTrovato
 
	add edi, 0ch							; posiziona all'inizio della table index successiva
	dec ebx
	jnz NoEnglishNameRecord

	mov edi, [NoEnglish]
	mov bl, byte ptr [VariabileMonoByte]

	jmp MacNameRecord

FullNameEQuasiTrovato:

	cmp byte ptr [VariabileQuaByte +3],00h			; controlla che sia encoding Microsoft (solo encoding Microsoft ha language id a 2 byte)
	jg FullNameTrovato

	add edi, 0ch					;posiziona all'inizio della table index successiva
	dec ebx
	jnz NoEnglishNameRecord

	mov edi, [NoEnglish]
	mov bl, byte ptr [VariabileMonoByte]

MacNameRecord:

	Call SetFilePointer, \
		[FileHandle], \		
		edi, \		
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \	
		OFFSET VariabileQuaByte, \	
		04h, \		
		OFFSET ByteLetti, \
		NULL	

	cmp dword ptr [VariabileQuaByte],04000000h			; Mac o Iso Inglese Americano
	je FullNameTrovato
 
	add edi, 0ch								;posiziona all'inizio della table index successiva
	dec ebx
	jnz MacNameRecord

	mov edi, [NoEnglish]
	add edi, 03h
	mov bl, byte ptr [VariabileMonoByte]

MacNoENameRecord:

	Call SetFilePointer, \
		[FileHandle], \		
		edi, \		
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \	
		OFFSET VariabileQuaByte, \	
		01h, \		
		OFFSET ByteLetti, \
		NULL	

	cmp byte ptr [VariabileQuaByte],04h			; solo per file senza lingua specifica
	je FullNameTrovato
 
	add edi, 0ch								;posiziona all'inizio della table index successiva
	dec ebx
	jnz MacNoENameRecord

	Call MessageBoxA, \
		0, \
		OFFSET FineNameTableTesto, \
		OFFSET wfd.cFileName, \
		MB_OK+MB_ICONERROR

	Call CloseHandle, \
		[FileHandle]

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 5: lettura offset e lunghezza del nome del carattere

FullNameTrovato:

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileDueByte +2, \	
		02h, \
		OFFSET ByteLetti, \
		NULL

	mov ebx, [VariabileDueByte]
	BSWAP ebx						; EBX = lunghezza del nome completo

	Call ReadFile, \
		[FileHandle], \
		OFFSET VariabileDueByte +2, \
		02h, \
		OFFSET ByteLetti, \
		NULL

	mov edx, [VariabileDueByte]
	BSWAP edx						; EDX = offset della stringa a partire dalla name storage

	add edx, [OffNameStorageBegin] 			; EDX = offset della stringa col nome completo a partire dall'inizio del file

;_________________ EDX = offset della stringa col nome completo a partire dall'inizio del file
;_________________ EBX = numero di byte da leggere

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 6: lettura nome carattere

	Call SetFilePointer, \
		[FileHandle], \
		edx, \	
		NULL, \
		FILE_BEGIN

	Call ReadFile, \
		[FileHandle], \
		OFFSET NomeCarattereWide, \
		ebx, \
		OFFSET ByteLetti, \
		NULL

	mov dword ptr [NomeCarattereWide + ebx], 00h		; 0 aggiunto alla fine della stringa nel caso
									; ci fosse già una stringa precedente più lunga

	cmp byte ptr	[NomeCarattereWide], 00			; controlla se il primo byte è 0 (WideChar)
	je WideChar
	
	mov ebx, offset NomeCarattereWide
	
	jmp MessaggioOk	

WideChar:

	xor ecx, ecx							; le seguenti 6 istruzioni servono a ruotare le coppie di byte
	mov eax, OFFSET NomeCarattereWide

ContinuaAGirare:
	
	ror word ptr [eax + ecx], 08h
	add ecx, 2h
	cmp ebx, ecx
	jne ContinuaAGirare

	call WideCharToMultiByte, \
  		CP_ACP, \
  		WC_COMPOSITECHECK, \ 
		OFFSET NomeCarattereWide, \		; cosa convertire
   		ebx, \ 				; numero byte
		OFFSET FileEPath, \ 			; dove metterlo ottimizzato riutilizzando FileEPath (che non serve più)
 		3Bh, \ 				; dimensioni del buffer (sbagliate!)
   		NULL, \
   		NULL

	mov ebx, offset FileEPath		; ottimizzato riutilizzando FileEPath (che non serve più)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 7: controllo lettere non valide

MessaggioOk:

	mov [VariabileQuaByte], ebx
	


ControllaCaratteri:

	cmp byte ptr [ebx], 3fh
	jg Velocizza
	je SostituisciCarattere

	cmp byte ptr [ebx], 22h
	je SostituisciCarattere

	cmp byte ptr [ebx], 2ah
	je SostituisciCarattere

	cmp byte ptr [ebx], 2Fh
	je SostituisciCarattere

	cmp byte ptr [ebx], 3ah
	je SostituisciCarattere

	cmp byte ptr [ebx], 3ch
	je SostituisciCarattere

	cmp byte ptr [ebx], 3eh
	je SostituisciCarattere

	cmp byte ptr [ebx], 00h
	je FineSostituisci

	add ebx, 01h
	jmp ControllaCaratteri

Velocizza:

	cmp byte ptr [ebx], 5ch
	je SostituisciCarattere

	cmp byte ptr [ebx], 7ch
	je SostituisciCarattere

	add ebx, 01h
	jmp ControllaCaratteri

SostituisciCarattere:

	mov byte ptr [ebx], 2dh
	add ebx, 01h
	jmp ControllaCaratteri

FineSostituisci:

	cmp byte ptr [ebx] -01h, 20h
	jne UltimoNonSpazio

	mov byte ptr [ebx], 00h

UltimoNonSpazio:

	mov ebx, [VariabileQuaByte]

	call lstrcat, \
		dword ptr ebx, \
		offset Estensione

;_________________ EBX = NOME CARATTERE.TTF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 8: controllo se il file ha già il nome corretto e modifica del nome

RiprovaGiaDoppio:

	Call CreateFileA, \
		ebx, \
		GENERIC_READ, \
		FILE_SHARE_READ, \
		NULL, \
		OPEN_EXISTING, \
		FILE_ATTRIBUTE_NORMAL, \			;file attributes
		NULL						;TemplateFile, handle to file with attributes to copy

	cmp eax, INVALID_HANDLE_VALUE			; esiste un file diverso con lo stesso nome?
	je FileConStessoNomeNonEsiste

	Call CloseHandle, \					; se esiste e lo hai aperto chiudilo!
		eax

	call lstrlenA, \
		dword ptr ebx

	add eax, ebx
	sub eax, 04h
	
	cmp byte ptr [eax] -01h, 29h		; se non c'è ')' in ultima posizione
	jne NonGiaDoppio

	cmp word ptr [eax] -04h, 2820h		; se non c'è '0(' in 4ultima posizione
	jne NonGiaDoppio

	add dword ptr [eax] -04h, 00010000h

	cmp byte ptr [eax] -02h, 3ah
	jne NonDuePunti				; se ci sono gia i file da (2) a (9) passa a (A)

	mov byte ptr [eax] -02h, 41h

NonDuePunti:

	jmp RiprovaGiaDoppio

NonGiaDoppio:

	mov dword ptr [eax], 29322820h

	jmp UltimoNonSpazio


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;passo 9: rinomina e chiudi

FileConStessoNomeNonEsiste:

	Call CloseHandle, \
		[FileHandle]

	Call lstrcmpA, \
		ebx, \
		offset wfd.cFileName

	cmp eax, 0					; il file ha già il nome giusto?
	jz DopoRinomina				; se si non serve rinominarlo

	call MoveFileA, \				; rinomina il file
		offset wfd.cFileName, \
		ebx

	cmp eax, 0					; ci sono stati errori durante la rinomina
	je ErroreRinomina

	add [Contatore], 00000001h

DopoRinomina:

	ret

ErroreRinomina:

	Call MessageBoxA, \				; se ci sono stati errori ecco il messaggio di errore
		0, \
		OFFSET WriteTesto, \
		OFFSET wfd.cFileName, \
		MB_OK+MB_ICONERROR

	ret



TableDirProc          endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Hex2Dec 		PROC     
	 xor esi,esi			; eax deve contenere il numero in esadecimale
        mov esi,offset Decimale+9
        mov ecx,0Ah
Keepgoing:
        xor edx,edx
        div ecx
        add dl,30h
        cmp dl,3Ah
        jl  printnow
        add dl,7
printnow:
        dec esi
        mov [esi],dl
        or eax,eax
        jnz Keepgoing
	 mov eax, [esi]		;eax contiene il numero in decimale
        RET
Hex2Dec              ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Ends
End Start
		
		