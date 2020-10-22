{*******************************************************************************}
{                                                                               }
{             модуль vmsHtmlConsts                                              }
{                  v.3.0.0.5                                                    }
{             створено 03/05/2012                                               }
{                                                                               }
{  Символьні константи для роботи з Html-об'єктами                              }
{                                                                               }
{*******************************************************************************}
unit vmsHtmlConsts;

interface

resourcestring
  C_VMS_HTML_BREAK       = '<br>';         // перенесення рядка
  C_VMS_HTML_LINE        = '<hr noshade>'; // горизонтальна лінія

  C_VMS_HTML_NBSP        = '&nbsp;';       // нерозривний пробіл
  C_VMS_HTML_LESS        = '&lt;';         // <
  C_VMS_HTML_MORE        = '&gt;';         // >
  C_VMS_HTML_AMPERSAND   = '&amp;';        // &
  C_VMS_HTML_PERCENT     = '&#8470;';      // %

  C_VMS_HTML_BODY_OPEN   = '<BODY>';
  C_VMS_HTML_BODY_CLOSE  = '</BODY>';
  C_VMS_HTML_OPEN        = '<!DOCTYPE HTML><HTML>';
  C_VMS_HTML_CLOSE       = '</HTML>';
  C_VMS_HTML_HEAD_OPEN   = '<HEAD><meta http-equiv="Content-Type" content="text/html; charset=windows-1251">';
  C_VMS_HTML_HEAD_CLOSE  = '</HEAD>';
  C_VMS_HTML_TABLE_CLOSE = '</TABLE>';
  C_VMS_HTML_TBODY_OPEN  = '<TBODY>';
  C_VMS_HTML_TBODY_CLOSE = '</TBODY>';
  C_VMS_HTML_STYLE_OPEN  = '<STYLE>';
  C_VMS_HTML_STYLE_CLOSE = '</STYLE>';
  C_VMS_HTML_BLANK       = 'about:blank';

  C_VMS_HTML_STYLE_TABLE = 'tr.err td{color:red;background:#FFFACD;vertical-align:baseline}'   +    // рядок таблиці з помилкою
                           'tr.met td{color:navy;background:#E8F0F8;vertical-align:baseline}'  +    // рядок таблиці з методом
                           'tr.obj td{color:black;background:#DEEAF0;vertical-align:baseline}' +    // рядок таблиці з об'єктом
                           'tr.txt td{color:black;background:#F5F5F5;vertical-align:baseline}' +    // рядок таблиці з простим текстом
                           'span{font:bold;color:black;background:#FFFF00;}' +                      // жирний текст на жовтому фоні
                           'caption{font:bold;font-size:130%;border-left:2px solid gray;border-right:2px solid gray;border-top:2px solid gray;color:#224466;' + //градієнтна заливка заголовку таблиці
                           'filter:progid:DXImageTransform.Microsoft.Gradient(GradientType=0,StartColorStr=#DDECFE,EndColorStr=#85ACE3);text-align:left;}';


  //дана конструкція описується в стилях та дозволяє додати зображення в html-документ без зовнішнього файла:
  //div.exit{width:16px;height:16px;border:none;background-image:url(data:image/png;base64, ...);}
  //конвертор image в base64: http://websemantics.co.uk/online_tools/image_to_data_uri_convertor/
  //використання в тілі html: <div class="exit" src=""/>

  //стрілка праворуч
  C_VMS_HTML_STYLE_IMG_ENTER = 'div.enter{width:16px;border:none;height:16px;background-image:' +
                               'url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgS' +
                               'W1hZ2VSZWFkeXHJZTwAAAKfSURBVHjaYvz//z8DJQAggFhgDDaz2ccVJHgt3rz8cu/9+z9FDGKCGxnYeRkY/rMxMLBzMTDwANlMnAwMzNwMDNxcDP9n84P1AQQQ' +
                               'E8wA9v8MBqV5Vgyz+9yVlFRFNjB8+DWV4e8/MQZG/C4ACCC4Af+APnn3n4lB20qWYU6/J0NYoHoW089/exn+/vfDZwBAAMEN+MHA+u7I8VcM+6/+Y3jwn5shM8O' +
                               'UoavCREdChGstw+//k4A2cGIzACCAGGGByGi5xJLhF/MEFV05Myt3PQY+IV4GI2kGBsH/3xlmrnnKsOv010v/2LmyGTh5jjDwAMNgFiQMAAIIYYDNMiDBwcvwg6' +
                               'mSW0IoV8lAhYdLQpJBV4aRwVvzH8OFax8YJq/7/OHdF5aZDMI8jcBA/A7SBxBAaAawQzAnrxEDM/t0bjERMxYxeQZeblaGRFsGBlX+3wwzdnxlOHaX6cT/eXyWI' +
                               'H0AAQSPRgYxDWBIMkAx4ydeLsbv7CzMDB9//Gf4+JuBYdYRBgZPbWag2RwMTKwM8PAACCAWtDDhZvj9L0dCgqvUQFtM+M53YYZvXxgZlET/M/z5+Yth2a4/P379' +
                               'YJrHwM1cBdMAEEAIA/7/12D8zzBdUUXQQVJRhuHcO3aG70DfSQn+ZXj36hfD2w9/7/77z5zHwMa4HaQapg0ggJBcwLRdQEZM4Y+YJMPpZ0wMPBwMDHysvxiePP7' +
                               'J8OMX82IGFpY8oPc+gL2IBAACCG4AIxuHxDdmAYbvX5kYBDj/Mvz58Z3h2cu/9/4zsjQysDAuwpWQAAIIbsB/FnYGJiYmBm7GXwyf3n4H2sqwjIGZuR4odQdfSg' +
                               'QIIHhKZGRmv/X3+3eG92+/vgRqjmVgYY4G5oM7DAQyK0AAMVKanQECDADMwNCYef7LugAAAABJRU5ErkJggg==);}';
  //стрілка ліворуч
  C_VMS_HTML_STYLE_IMG_EXIT  = 'div.exit{width:16px;border:none;height:16px;background-image:' +
                               'url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgS' +
                               'W1hZ2VSZWFkeXHJZTwAAAKbSURBVHjaYvz//z8DJQAggFhgDEajmQwMP34zMLADhViZGRi+AdmMQAl2VgaGf/8YGN5/9+IX5e4XleRTe/j619lfx2JNQPoAAogJ' +
                               'v/lAE/7+EwJqniCnKLhpZqerWmWRPQMHM7s2TAVAAOE34O8/d6Zvv/YG+mvmz50ayGzgqMDw7j8Tw19mNrgSgABiwbQUaOu//2wMv/+2iYpw5RRnWbJbOGgw3Pv' +
                               'KxHD76j+GIyffMPxkYPkIUw4QQCwYmn/8MWP4/We6s4OSUVamFcMXLmGGtdcYGD69+cRwYs8VhpvXX59l4GQvhWkBCCBkAzgZvv2q5BfiyswptBIxddRl2HGLhe' +
                               'H8/X8M357cZ7h/7ub3L2+/T2Pg525iYGH6BNMEEEAIA/783WVur2KTmWbF8OifMEP+SmDAf/jO8P/uGYbPr96cZ2BmyWLgZD3BwACKdkTUAwQQ3AAmRkZOTj4Oh' +
                               'oNP2Bl23mVgeP4OKPbzPwM/EyMDHzfHj09/uT4ycHAzMHABMTs33ACAAILHwj8WJrsDO25MXDJx61fO93cZNGT+MXDyczHw61kxWDvoWEqLcxwDhk0t0HIe5GAD' +
                               'CCBENP5n+AZ0YuHv378C7x07f/P1hQsMEtzfGN7/ZWI4/U2WQc5IV0BFQ6SJieH/NmAs6cK0AQQQajr4D4QszLv/s7Gbvnnyes7jMxf/8/x8A4yd/wznnnMx/BJ' +
                               'RZhCUErdlYGLaCtMCEEDYExIj42egotSfP/5GPb3x4Pa/t08ZBLn+MLz6wsjwmYGXgZGNQxSmFCCA8KdERsYV/5nYXN69/Dz/w9OXDDxMwCTEwsjwn5kDrgQggJ' +
                               'gIZjcmhkdAXUk/vv+LeP/669M/v34zMLKy3odJAwQQI6XZGSDAABOQ3NieFWOEAAAAAElFTkSuQmCC);}';
  //червоний хрест - помилка
  C_VMS_HTML_STYLE_IMG_ERR   = 'div.err{width:16px;border:none;height:16px;background-image:' +
                               'url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgS' +
                               'W1hZ2VSZWFkeXHJZTwAAAP/SURBVHjaYiyXlGT4/vu3vIag4BKh//8NL3/7lvL/378VbP/+MbD+/8/ABKQZgfjv378MzAwM3hri4st//vt39+G9e1GcTEzXAQKI' +
                               '2YKHR16Oh2dJpLm5jZmmJtu3O3e8n/7794Dx///LLAwMDECa4T8I//vnoy8ktMw7NZVPXl9f4vWdOxYfP3w4ChBAzDGKirtiTEwshfPzGRhCQxmUnjxh/Xfxoud' +
                               'TJqZ7TAwMV0AGAK33MmZnX+YUFcXHmpfHwK6uziDPyyv1/sULB4AAYhHm4NAVEhZmYODmZmD49ImBJSuLwe7LF86/q1fPPs/N/Quo+ZPunz8rbIKDednj4hgY3r' +
                               '0DGcjAIy/PICQmpgYQQMzq///f//nhg4fykydsjBISQDczMrAYGTFIPX/O9uvixSChX78iHNzcuHiBBoM0Mnz4wPD/1CmGM0uW/Lx06FAhQAAx27CzX3706dN9p' +
                               'tevveRevWJlAhkCVMhiYMAg/PQpk4y4OIsAUDMjVPO/M2cYLmzc+OfE0aNF///8mQYQQMx2PDwM/3//vvLkx48Hf1688JJ79oyFWUQEHHgcGhoMXPr6DEygQHz7' +
                               'luHvyZMMZ7Zv/3PqwoWCf3//TmUBuhYggJhtgX5nBIY2w58/l1/8/Hn15+vXQZJv3zKzgQxhYmJg/POH4f/HjwzfgZrP7t//9/ydO0n//v2bwwyKIaABAAHEwv/' +
                               '1KwNQgOEfUPF/NrYP/7i4/n0GOvPLixcMYO8AwV+gGlAA/2Vh+Qe07AMbUAyEQekEIICYXVlZGf6CbOHg8DGWlV1j9fEj91egcz++fs3w9v59ho9A/BvodyY2Ng' +
                               'Y5GRlmFkHBgNevXj1ggKYTgABiAiYQhv/s7F4WampL7T594v0FtPk/SAKI+YFOFABqZObgYPgPdOFPoCv05OQ4jaytZzMyM0eC1AEEEAsjO7ufiabmEru3b3m/P' +
                               '3rE8JsBAniALnvEyvrvDyPjPyVmZpY/QOf+BeJfwHSgq6LCCfTu7JsHD7ICBBCLhpbWEvfv33l/3r7N8AtqMw8XF8MdTs6fF79/zwDG0EeWv38Xq3BwcP8FuugP' +
                               'UP73s2cMJiYm3MBwmwkQQEw/v3599AXoTCagjaDY4BIQYHgoJPTn3LdvxX///VsAdOb6q+/fpz76+vU7JzDGQFEKCo8fv34xfH///gVAADGbffp08BUPj7mCmJg' +
                               'ULzMzw2V+/j9nXr0qAAbsVGYgHxzFf/9eef3p0wNWLi5PGTk51v/AKD5+9OiNJ+fPxwIEELMnG9vrD2/eHP7CyWn5hotL+PLjx/l/gCmMCZQGgE5mAEUVMKBBof' +
                               '7p/fsHf5iYPB49ePDg4fXr8cyMjCcBAgwAkC29pEiNXvgAAAAASUVORK5CYII=);}';

implementation

end.
