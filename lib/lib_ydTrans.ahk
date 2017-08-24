/*
有道翻译
*/

;引入json解析文件
#Include lib_json.ahk

global TransEdit,transEditHwnd,transGuiHwnd,NativeString

youdaoApiInit:
	global youdaoApiString := "https://openapi.youdao.com/api"
	return

setTransGuiActive:
	WinActivate, ahk_id %transGuiHwnd%
	return

ydTranslate(ss)
{
	transStart:
		ss := RegExReplace(ss, "\s", " ") ;把所有空白符换成空格，因为如果有回车符的话，json转换时会出错
		
		;~ global 
		NativeString := Trim(ss)

	transGui:
		;~ WinClose, 有道翻译
		MsgBoxStr := NativeString ? lang_yd_translating : ""

		DetectHiddenWindows, On ;可以检测到隐藏窗口
		WinGet, ifGuiExistButHide, Count, ahk_id %transGuiHwnd%
		if(ifGuiExistButHide)
		{
			ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
			ControlFocus, , ahk_id %transEditHwnd%
			WinShow, ahk_id %transGuiHwnd%
		}
		else ;IfWinNotExist,  ahk_id %transGuiHwnd% ;有道翻译
		{
			;~ MsgBox, 0
			
			Gui, new, +HwndtransGuiHwnd , %lang_yd_name%
			Gui, +AlwaysOnTop -Border +Caption -Disabled -LastFound -MaximizeBox -OwnDialogs -Resize +SysMenu -Theme -ToolWindow
			Gui, Font, s10 w400, Microsoft YaHei UI ;设置字体
			Gui, Font, s10 w400, 微软雅黑
			gui, Add, Button, x-40 y-40 Default, OK  
			
			Gui, Add, Edit, x-2 y0 w504 h405 vTransEdit HwndtransEditHwnd -WantReturn -VScroll , %MsgBoxStr%
			Gui, Color, ffffff, fefefe
			Gui, +LastFound
			WinSet, TransColor, ffffff 210
			;~ MsgBox, 1
			Gui, Show, Center w500 h402, %lang_yd_name%
			ControlFocus, , ahk_id %transEditHwnd%
			SetTimer, setTransActive, 50
		}
		;~ DetectHiddenWindows, On ;可以检测到隐藏窗口

		if(NativeString) ;如果传入的字符串非空则翻译
		{
			;~ MsgBox, 2
			SetTimer, ydApi, -1
			return
		}

		Return


	ydApi:
		UTF8Codes := "" ;重置要发送的代码
		SetFormat, integer, H

		; 参数
		salt := "capslock"
		youdaoApiKey := CLsets.TTranslate.ApiKey
		youdaoApiSecret := CLsets.TTranslate.ApiSecret
		signStr := youdaoApiKey . NativeString . salt . youdaoApiSecret
		youdaoApiSign := MD5(signStr)
		UTF8Codes := UTF8encode(NativeString)

		if(youdaoApiKey == "" || youdaoApiSecret == "")
		{
			MsgBoxStr := lang_yd_needKey
			goto, setTransText
		}

		requestUrl := youdaoApiString . "?q=" . UTF8Codes . "&from=auto&to=auto&appKey=" . youdaoApiKey . "&salt=" . salt . "&sign=" . youdaoApiSign
		request := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		request.Open("GET", requestUrl)

		try
		{
			request.Send()
		}
		catch
		{
			MsgBoxStr := lang_yd_errorNoNet
			goto, setTransText
		}

	afterSend:
		responseStr := request.ResponseText
		transJson := JSON.Load(responseStr)

		returnError := transJson.errorCode
		if(returnError) ;如果返回错误结果，显示出相应原因
		{
			MsgBoxStr := getErrorInfo(returnError)
			goto, setTransText
			return
		}
		else if (transJson.basic) { ;如果成功返回词典翻译
			if (CLsets.TTranslate.isRecordWord == 1) {
				recordQueryWord(transJson.query)
			}
		}
	
 	;================拼MsgBox显示的内容
	{

		MsgBoxStr:= % transJson.query . "`t"   ;原单词
		if(transJson.basic.phonetic)
		{
			MsgBoxStr:=% MsgBoxStr . "[" . transJson.basic.phonetic . "] "  ;读音
		}
		MsgBoxStr:= % MsgBoxStr . "`r`n`r`n" . lang_yd_trans . "`r`n" ;分隔，换行
		;~ MsgBoxStr:= % MsgBoxStr . "--有道翻译--`n"
		Loop
		{
			if (transJson.translation[A_Index])
			{
				if (%A_Index%>1)
				{
					MsgBoxStr:=% MsgBoxStr . A_Space . ";" . A_Space  ;给每个结果之间插入" ; "
				}
				MsgBoxStr:= % MsgBoxStr . transJson.translation[A_Index]                                     ;翻译结果
			}
			else
			{
				MsgBoxStr:= % MsgBoxStr . "`r`n`r`n" . lang_yd_dict . "`r`n"
				break
			}
		}
		;~ MsgBoxStr:= % MsgBoxStr . "--有道词典结果--`n"
		Loop
		{
			if (transJson.basic.explains[A_Index])
			{
				if (A_Index>1)
				{
					;~ MsgBoxStr:=% MsgBoxStr . A_Space . ";" . A_Space  ;给每个结果之间插入" ; "
					MsgBoxStr:=% MsgBoxStr . "`r`n"   ;每条短语换一行
				}
				MsgBoxStr:= % MsgBoxStr . transJson.basic.explains[A_Index]                                      ;有道词典结果
			}
			else
			{
				MsgBoxStr:= % MsgBoxStr . "`r`n`r`n" . lang_yd_phrase . "`r`n"
				break
			}
		}
		;~ MsgBoxStr:= % MsgBoxStr . "--短语--`n"
		Loop
		{
			if (transJson.web[A_Index])
			{
				if (A_Index>1)
				{
					MsgBoxStr:=% MsgBoxStr . "`r`n"   ;每条短语换一行
				}
				MsgBoxStr:= % MsgBoxStr . transJson.web[A_Index].key . A_Space . A_Space   ;短语  
				thisA_index:=A_Index
				Loop
				{
					if(transJson.web[thisA_index].value[A_Index])
					{
						if (A_Index>1)
						{
							MsgBoxStr:=% MsgBoxStr . A_Space . ";" . A_Space  ;给每个结果之间插入" ; "
						}
						MsgBoxStr:= % MsgBoxStr . transJson.web[thisA_index].value[A_Index]
					}
					else
					{
						break
					}
				}
			}
			else
			{
				break
			}
		}
	}
	;~ MsgBox, % MsgBoxStr
	setTransText:
		ControlSetText, , %MsgBoxStr%, ahk_id %transEditHwnd%
		ControlFocus, , ahk_id %transEditHwnd%
		SetTimer, setTransActive, 50
		return 
		;================拼MsgBox显示的内容

	ButtonOK:
		Gui, Submit, NoHide

		TransEdit:=RegExReplace(TransEdit, "\s", " ") ;把所有空白符换成空格，因为如果有回车符的话，json转换时会出错
		NativeString:=Trim(TransEdit)
		;~ goto, ydApi
		goto, transGui
		return		

}


;确保激活
setTransActive:
	IfWinExist, ahk_id %transGuiHwnd%
	{
		SetTimer, ,Off
		WinActivate, ahk_id %transGuiHwnd%
	}
	return

;记录查询单词
recordQueryWord(queryWord) {

	;中文单词处理
	queryFirstWord := SubStr(queryWord, 1 [, 1])
	foundPos := RegExMatch(queryFirstWord, "[a-z|A-Z]")
	if(!foundPos)
	{
		queryWord := "[" queryWord "]"
	}

	;记录单词
	IfNotExist, wordRecord
	{
		FileCreateDir, wordRecord
	}
	FileAppend, %queryWord%`n, wordRecord\wordRecord.txt
}

; TODO 用数组表示
getErrorInfo(code) {
	if (code==101) {
		errorInfo := "【101】缺少必填的参数，出现这个情况还可能是et的值和实际加密方式不对应"
	} else if(code==102) {
		errorInfo := "【102】不支持的语言类型"
	} else if(code==103) {
		errorInfo := "【103】翻译文本过长"
	} else if(code==104) {
		errorInfo := "【104】不支持的API类型"
	} else if(code==105) {
		errorInfo := "【105】不支持的签名类型"
	} else if(code==106) {
		errorInfo := "【106】不支持的响应类型"
	} else if(code==107) {
		errorInfo := "【107】不支持的传输加密类型"
	} else if(code==108) {
		errorInfo := "【108】appKey无效，注册账号， 登录后台创建应用和实例并完成绑定， 可获得应用ID和密钥等信息，其中应用ID就是appKey（ 注意不是应用密钥）"
	} else if(code==109) {
		errorInfo := "【109】batchLog格式不正确"
	} else if(code==110) {
		errorInfo := "【110】无相关服务的有效实例"
	} else if(code==111) {
		errorInfo := "【111】开发者账号无效，可能是账号为欠费状态"
	} else if(code==201) {
		errorInfo := "【201】解密失败，可能为DES,BASE64,URLDecode的错误"
	} else if(code==202) {
		errorInfo := "【202】签名检验失败"
	} else if(code==203) {
		errorInfo := "【203】访问IP地址不在可访问IP列表"
	} else if(code==301) {
		errorInfo := "【301】辞典查询失败"
	} else if(code==302) {
		errorInfo := "【302】翻译查询失败"
	} else if(code==303) {
		errorInfo := "【303】服务端的其它异常"
	} else if(code==401) {
		errorInfo := "【401】账户已经欠费停"
	} else {
		errorInfo := "【" . code . "】其它错误"
	}
	return errorInfo
}

MD5(string, encoding = "UTF-8", byref hash = 0, byref hashlength = 0)
{
	chrlength := (encoding = "CP1200" || encoding = "UTF-16") ? 2 : 1
    length := (StrPut(string, encoding) - 1) * chrlength
    VarSetCapacity(data, length, 0)
    StrPut(string, &data, floor(length / chrlength), encoding)

	static h := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "a", "b", "c", "d", "e", "f"]
    static b := h.minIndex()
    hProv := hHash := o := ""
    if (DllCall("advapi32\CryptAcquireContext", "Ptr*", hProv, "Ptr", 0, "Ptr", 0, "UInt", 24, "UInt", 0xf0000000))
    {
        if (DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", 0x8003, "UInt", 0, "UInt", 0, "Ptr*", hHash))
        {
            if (DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", &data, "UInt", length, "UInt", 0))
            {
                if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", 0, "UInt*", hashlength, "UInt", 0))
                {
                    VarSetCapacity(hash, hashlength, 0)
                    if (DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", 2, "Ptr", &hash, "UInt*", hashlength, "UInt", 0))
                    {
                        loop % hashlength
                        {
                            v := NumGet(hash, A_Index - 1, "UChar")
                            o .= h[(v >> 4) + b] h[(v & 0xf) + b]
                        }
                    }
                }
            }
            DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
        }
        DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
    }

	; 不知道为什么多了 0x，暂时处理直接删除
	return RegExReplace(o, "0x", "")
}


