var
    purchaseApp = angular.module('remoteApp', [])
        .controller('remoteController', function ($scope, $http) {
            $scope.logList = [];
            $scope.commandTabs = [];
            $scope.delayCommands = [];
            $scope.refreshPeriod = 2000;
            $scope.timeOut = 100000;
            $scope.tabCounter = 0;
            $scope.currentLang = localStorage['lang'] || navigator.language.split('-')[0] || navigator.userLanguage.split('-')[0];
            $scope.marketPlace = 'mpSpos';
            $scope.arrCommands = [
                //[command, id phrase, visible]
                ['execsql', 'cmdsql', true],
                ['execsqlfile', '', false],
                ['executecmd', 'cmdcmd', true],
                ['executecmdfile', '', false],
                ['infofile', 'cmdinfo', true],
                ['infostatus', 'cmdstatus', false],
                ['showmessage', 'cmdmessage', true],
                ['paramcfgdel', 'cmdcfg', true],
                ['paramcfgget', 'cmdcfg', true],
                ['paramcfgset', 'cmdcfg', true],
                ['receivefile', 'cmdfile', true],
                ['refresh', 'cmdrefresh', true],
                ['remoteact', 'mnuremoteact', true],
                ['sendfile', 'cmdsendfile', true],
                ['servicereload', '', false],
                ['servicestop', '', false],
                ['transfer', '', false]
            ];
            $scope.hostList = [{
                index: -1,
                external_device_id: -1,
                description: '',
                ip_address: window.location.host,
                checked: true
            }];

            $scope.currentHost = {
                index: -1,
                external_device_id: -1,
                ip_address: ''
            };

            $scope.initialize = function (marketPlace, timeOut, refreshPeriod) {
                $scope.marketPlace = marketPlace;
                $scope.timeOut = timeOut;
                $scope.refreshPeriod = refreshPeriod * 1000;
                $scope.vmGetCommandList();
                if ($scope.marketPlace == 'mpStp') {
                    $scope.vmGetSposList();
                }
                ;

            };

            $scope.vmExecute = function () {
                var command = $('#list :selected').val();
                var text = $('#text-' + command).val();

                if (command == 'execsqlfile') {
                    $scope.vmSendFile('execsqlfile');
                } else if (command == 'executecmdfile') {
                    $scope.vmSendFile('executecmdfile');
                } else if (command == 'sendfile') {
                    $scope.vmSendFile('sendfile', text);
                } else {
                    localStorage[command] = text;
                    for (var i = 0; i < $scope.hostList.length; i++) {
                        if ($scope.hostList[i].checked) {
                            var ipAddress = $scope.hostList[i].ip_address;
                            if (command == 'paramcfgdel') {
                                $scope.vmSendText(command, text, true, ipAddress);
                            } else if (command == 'paramcfgset') {
                                $scope.vmSendText(command, text, true, ipAddress);
                            } else if (command == 'paramcfgget') {
                                $scope.vmSendText(command, text, false, ipAddress);
                            } else if (command == 'infostatus') {
                                $scope.vmSendJSONInfo(command, ipAddress);
                            } else if (command == 'infofile') {
                                $scope.vmSendText(command, text, true, ipAddress);
                            } else if (command == 'showmessage') {
                                $scope.vmSendText(command, text, true, ipAddress);
                            } else if (command == 'receivefile') {
                                $scope.vmReceiveFile('receivefile', text, ipAddress);
                            } else if (command == 'servicereload') {
                                $scope.vmSendJSONInfo(command, ipAddress);
                            } else if (command == 'servicestop') {
                                $scope.vmSendJSONInfo(command, ipAddress);
                            } else if (['executecmd', 'refresh', 'remoteact', 'execsql', 'transfer'].indexOf(command) > -1) {
                                $scope.vmSendDelayRequest(command, {
                                    basecmd: command,
                                    text: text,
                                    ip_address: ipAddress
                                });
                            }
                            ;
                        }
                    }
                }
            };

            createMainTabs = function () {
                for (var i = 0; i < $scope.arrCommands.length; i++) {
                    var content = $('#content'),
                        ul = $('#ul-command');
                    li = $('<li />')
                        .attr({
                            command: $scope.arrCommands[i][0],
                            hidden: !$scope.arrCommands[i][2],
                            id: 'li-' + $scope.arrCommands[i][0]
                        })
                        .addClass('tab-li')
                        .appendTo(ul)
                        .css('display', 'none'),
                        aHref = $('<a />')
                            .attr({
                                href: '#',
                                onclick: "openTab(event, '" + $scope.arrCommands[i][0] + "')",
                                'data-id_phrase': $scope.arrCommands[i][1]
                            })
                            .addClass('tab-links')
                            .appendTo(li)
                            .text(jQuery.fn.vmGetTranslate($scope.arrCommands[i][1], $scope.currentLang)),
                        //tabs
                        tabcontent = $('<div />')
                            .attr({
                                id: 'tab-' + $scope.arrCommands[i][0]
                            })
                            .addClass('tab-content')
                            .appendTo(content),
                        area = $('<textarea />')
                            .attr({
                                id: 'text-' + $scope.arrCommands[i][0]
                            })
                            .addClass('tab-textarea')
                            .appendTo(tabcontent);

                    area.val(loadFromStorage($scope.arrCommands[i][0]));
                }
                ;
            };

            openTab = function (event, tabName) {
                var i, tabContent, tabLinks, tabLi, li, tab;
                tabContent = $('.tab-content');
                for (i = 0; i < tabContent.length; i++) {
                    tabContent[i].style.display = 'none';
                }
                tabLinks = $('.tab-links');
                for (i = 0; i < tabLinks.length; i++) {
                    tabLinks[i].className = tabLinks[i].className.replace(' active', '');
                }
                ;
                tabLi = $('.tab-li');
                for (i = 0; i < tabLi.length; i++) {
                    tabLi[i].className = tabLi[i].className.replace(' menu-li-active', '');
                }
                ;

                tab = $('#tab-' + tabName)[0];
                if (tab) {
                    tab.style.display = 'block';
                    tab.className += ' active';
                }
                ;
                li = $('#li-' + tabName)[0];
                if (li) {
                    li.className += ' menu-li-active';
                }
                ;
            };

            deleteTab = function (event, tabName) {
                event.target.closest('li').remove();
                $('#tab-' + tabName)[0].remove();
                openTab(event, $('#list :selected').val());
                event.stopPropagation();
            };

            addTab = function (command, text, host) {
                $scope.tabCounter++;
                var content = $('#content'),
                //menu
                    ul = $('#ul-command'),
                    li = $('<li />')
                        .attr({
                            command: command,
                            id: 'li-' + $scope.tabCounter
                        })
                        .addClass('tab-li')
                        .appendTo(ul),
                    aHref = $('<a />')
                        .attr({
                            href: '#',
                            onclick: 'openTab(event, "' + $scope.tabCounter + '")'
                        })
                        .addClass('tab-links')
                        .appendTo(li)
                        .text(host + '#' + $scope.tabCounter),
                    span = $('<span />')
                        .attr({
                            onclick: 'deleteTab(event, "' + $scope.tabCounter + '")'
                        })
                        .addClass('tab-closebtn')
                        .appendTo(aHref)
                        .text('X'),

                //tabs
                    tabcontent = $('<div />')
                        .attr({
                            id: 'tab-' + $scope.tabCounter
                        })
                        .addClass('tab-content')
                        .appendTo(content),
                    area = $('<textarea />')
                        .attr({
                            id: 'text-' + $scope.tabCounter
                        })
                        .addClass('tab-textarea')
                        .appendTo(tabcontent)
                        .text(text);

                openTab(event, $scope.tabCounter);
            };

            $scope.vmListChange = function vmListChange(event) {
                var command = $('#list :selected').val(),
                    tabLi = $('[command]');

                for (i = 0; i < tabLi.length; i++) {
                    if (tabLi[i].getAttribute('command') == command) {
                        tabLi[i].style.display = '';
                    }
                    else {
                        tabLi[i].style.display = 'none';
                    }
                }
                ;
                openTab(event, command);
            };

            $scope.vmSendFile = function (command, fileName) {
                var openFile = document.createElement('input');
                openFile.type = 'file';
                openFile.addEventListener('change', function (event) {
                        event.preventDefault();
                        var formData = new FormData('file', openFile.files);
                        formData.enctype = 'multipart/form-data';
                        var fileNames = [];
                        for (var i = 0, file; file = openFile.files[i]; i++) {
                            formData.append(file.name, file);
                            fileNames.push(file.name);
                        }
                        ;
                        if (!fileName || 0 === fileName.length || fileName === undefined) {
                            fileName = fileNames.join()
                        }
                        ;

                        for (var i = 0; i < $scope.hostList.length; i++) {
                            if ($scope.hostList[i].checked) {
                                var ipAddress = $scope.hostList[i].ip_address;

                                $.ajax({
                                    url: '/?command=' + command + '&filename=' + fileName + (ipAddress == window.location.host ? '' : '&host=' + ipAddress),
                                    data: formData,
                                    timeout: $scope.timeOut,
                                    processData: false,
                                    contentType: false,
                                    type: 'POST',
                                    scriptCharset: 'windows-1251',
                                    dataType: 'json',
                                    error: function (jqxhr, status, errorMsg, response) {
                                        addTab(command, errorMsg, ipAddress);
                                        vmAddLog({
                                            "value": [{
                                                host: ipAddress,
                                                command: command,
                                                status: 'error',
                                                info: fileName,
                                                text: errorMsg
                                            }]
                                        });
                                    },
                                    success: function (data, textStatus, xhr) {
                                        var dataJson = data;
                                        dataJson.value[0].info = fileName;
                                        vmAddLog(dataJson);
                                        if ((command === 'executecmdfile') || (command === 'execsqlfile')) {
                                            addTab(command, dataJson.value[0].text, ipAddress);
                                        }
                                    }
                                });
                            }
                        }
                    }
                )
                ;
                openFile.click();
            };

            $scope.vmSendJSONInfo = function (command, host) {
                var ipAddress = host || window.location.host;
                $.ajax({
                    url: '/',
                    type: 'GET',
                    timeout: $scope.timeOut,
                    data: {
                        command: command,
                        host: (ipAddress == window.location.host ? '' : ipAddress)
                    },
                    scriptCharset: 'windows-1251',
                    dataType: 'json',
                    error: function (jqxhr, status, errorMsg, response) {
                        addTab(command, errorMsg, ipAddress);
                        vmAddLog({
                            "value": [{
                                host: ipAddress,
                                command: command,
                                status: 'error',
                                text: errorMsg
                            }]
                        });
                    },
                    success: function (data) {
                        var dataJson = data;
                        addTab(command, dataJson.value[0].text, ipAddress);
                        vmAddLog(dataJson);
                    }
                })
            };

            $scope.vmSendDelayRequest = function (command, params) {
                var ipAddress = params.ip_address || window.location.host;
                $.ajax({
                    url: '/',
                    type: 'POST',
                    timeout: $scope.timeOut,
                    scriptCharset: 'windows-1251',
                    data: {
                        command: 'delayrequest',
                        basecmd: params.basecmd,
                        host: (ipAddress == window.location.host ? '' : ipAddress),
                        text: params.text
                    },
                    dataType: 'json',
                    error: function (jqxhr, status, errorMsg, response) {
                        if (typeof response == 'undefined') {
                            response = 'Request is empty';
                        }
                        ;
                        vmAddLog({
                            "value": [{
                                host: ipAddress,
                                command: command,
                                status: 'error',
                                info: params.text,
                                text: errorMsg + ' <p>An error has occurred:</p> ' + response
                            }]
                        });
                    },
                    success: function (data) {
                        var dataJson = data;
                        dataJson.value[0].info = params.text;

                        var cmdInfo = {};
                        cmdInfo.command = command;
                        cmdInfo.ip_address = dataJson.value[0].host;
                        cmdInfo.id = dataJson.value[0].text;
                        cmdInfo.timerId = setInterval(function () {
                            $scope.vmSendDelayRespons(cmdInfo.command, cmdInfo.id, ipAddress);
                        }, $scope.refreshPeriod);
                        $scope.delayCommands.push(cmdInfo);
                        vmAddLog(dataJson);
                    }
                })
            };

            $scope.vmSendDelayRespons = function (command, id, host) {
                host = host || window.location.host;
                $.ajax({
                    url: '/',
                    type: 'GET',
                    timeout: $scope.timeOut,
                    scriptCharset: 'windows-1251',
                    dataType: 'json',
                    data: {
                        command: 'delayrespons',
                        basecmd: command,
                        id: id,
                        host: (host == window.location.host ? '' : host)
                    },
                    error: function (jqxhr, status, errorMsg, response) {
                        if (typeof response == 'undefined') {
                            response = 'Response is empty';
                        }
                        ;
                        for (i = 0; i < $scope.delayCommands.length; i++) {
                            if ($scope.delayCommands[i].id == id) {
                                clearInterval($scope.delayCommands[i].timerId);
                                $scope.delayCommands.splice(i, 1);
                                break;
                            }

                        }
                        ;
                        addTab(command, response, host);
                        vmAddLog({
                            value: [{
                                host: host,
                                command: command,
                                status: 'error',
                                info: '',
                                text: errorMsg + ' <p>An error has occurred:</p> ' + response
                            }]
                        });
                    },
                    success: function (data, status, jqxhr) {
                        if (jqxhr.status == 200) {
                            var dataJson = data;
                            for (i = 0; i < $scope.delayCommands.length; i++) {
                                if ($scope.delayCommands[i].id == id) {
                                    clearInterval($scope.delayCommands[i].timerId);
                                    $scope.delayCommands.splice(i, 1);
                                    break;
                                }

                            }
                            ;
                            addTab(command, dataJson.value[0].text, host);
                            vmAddLog(dataJson);
                        }
                    }
                })
            };

            $scope.vmListClear = function () {
                $scope.logList = [];
            };

            $scope.vmGetSposList = function () {
                $http({
                    method: 'GET',
                    url: '/?command=sposlist'
                }).then(
                    function success(response) {
                        $scope.hostList = [{
                            external_device_id: -1,
                            description: '',
                            ip_address: window.location.host,
                            checked: true
                        }];

                        for (var i = 0; i < response.data.value.length; i++) {
                            var rObj = response.data.value[i];
                            //external_device_id, ip_address, description
                            if (!rObj.ip_address) {
                                rObj.ip_address = rObj.description;
                                var arrIpAddress = rObj.description.match(/(.+?)-(.+?):/);
                                if (arrIpAddress != null && arrIpAddress.length > 0) (
                                    rObj.ip_address = arrIpAddress[2] + ':8080' || arrIpAddress[1] || arrIpAddress[0]
                                );
                            }
                            ;
                            $scope.hostList.push(rObj);
                        }
                        ;
                    },
                    function error(response) {
                        //vmAddLog({
                        //    "value": [{
                        //        host: window.location.host,
                        //        command: 'hostList',
                        //        status: 'error',
                        //        info: '',
                        //        text: ' <p>An error has occurred:</p> ' + status
                        //    }]
                        //});
                    }
                )
            };

            $scope.vmGetCommandList = function () {
                $http.get('/?command=commandlist')
                    .success(function (data, status, headers, config) {
                        for (var i = 0; i < data.value.length; i++) {
                            var rObj = {};
                            rObj.id = i;
                            if (data.value[i] == 'sep') {
                                rObj.command = '';
                                rObj.idPhrase = 'sep';
                                rObj.text = jQuery.fn.vmGetTranslate('sep', $scope.currentLang);
                            }
                            else {
                                rObj.command = data.value[i];
                                rObj.idPhrase = 'mnu' + data.value[i];
                                rObj.text = jQuery.fn.vmGetTranslate('mnu' + data.value[i], $scope.currentLang)
                            }
                            $scope.commandTabs.push(rObj);
                        }
                        ;
                        createMainTabs();
                        $('#li-' + $('#list option:first-child').val()).css('display', 'block');
                        openTab(event, $('#list option:first-child').val());
                        $('#langlist').val($scope.currentLang);
                        jQuery.fn.vmTranslate($scope.currentLang);
                    })
                    .error(function (data, status, header, config) {
                        //vmAddLog({
                        //    "value": [{
                        //        host: window.location.host,
                        //        command: 'hostList',
                        //        status: 'error',
                        //        info: '',
                        //        text: ' <p>An error has occurred:</p> ' + status
                        //    }]
                        //});
                    });
            };

            $scope.vmReceiveFile = function (command, filename, host) {
                host = host || window.location.host;
                if (!filename || 0 === filename.length || filename === undefined) {
                    vmAddLog({
                        "value": [{
                            host: host,
                            command: command,
                            status: 'error',
                            text: 'File name is empty!'
                        }]
                    });
                    return;
                }
                ;
                var arr = filename.replace(/(\r\n|\n|\r)/gm, '').split(';');
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i] != '') {
                        var link = document.createElement('a');
                        link.download = name;
                        link.href = '/?command=' + command + '&filename=' + arr[i] + (host == window.location.host ? '' : '&host=' + host);
                        link.click();
                    }
                    ;
                }
            };

            $scope.vmSendText = function (command, text, outResult, host) {
                host = host || window.location.host;
                outResult = outResult || false;
                if (outResult && (!text || 0 === text.length || text === undefined)) {
                    addTab(command, 'Command text is  empty!', host);
                    vmAddLog({
                        "value": [{
                            host: host,
                            command: command,
                            status: 'error',
                            info: text,
                            text: 'Command text is  empty!'
                        }]
                    });
                    return;
                }
                ;
                $.ajax({
                    url: '/?command=' + command,
                    type: 'GET',
                    timeout: $scope.timeOut,
                    scriptCharset: 'windows-1251',
                    data: {
                        text: encodeURI(text).replace(/&/g,"%26"),
                        host: (host == window.location.host ? '' : host)
                    },
                    dataType: 'json',
                    error: function (jqxhr, status, errorMsg, response) {
                        if (typeof response == 'undefined') {
                            response = 'Response is empty';
                        }
                        ;
                        addTab(command, errorMsg + '.\nAn error has occurred:\n' + response, host);
                        vmAddLog({
                            "value": [{
                                host: host,
                                command: command,
                                status: 'error',
                                info: text,
                                text: errorMsg + ' <p>An error has occurred:</p> ' + response
                            }]
                        });
                    },
                    success: function (data) {
                        var dataJson = data;
                        dataJson.value[0].info = text;
                        vmAddLog(dataJson);
                        if ((command === 'paramcfgget') || (command === 'infofile') || (command == 'executecmd')) {
                            addTab(command, dataJson.value[0].text, host);
                        }
                        ;
                    }
                })
            };

            vmZeroFill = function (i) {
                return (i < 10 ? '0' : '') + i
            };

            loadFromStorage = function (key) {
                var text = localStorage[key] || '';
                return text;
            };

            function vmAddLog(jsonObj) {
                var date = new Date();

                $scope.logList.push({
                    time: vmZeroFill(date.getDate()) + '.' + vmZeroFill(date.getMonth() + 1) + '.' + vmZeroFill(date.getFullYear()) + ' ' + vmZeroFill(date.getHours()) + ':' + vmZeroFill(date.getMinutes()) + ':' + vmZeroFill(date.getSeconds()),
                    host: jsonObj.value[0].host,
                    command: jsonObj.value[0].command,
                    status: jsonObj.value[0].status,
                    sendinfo: jsonObj.value[0].info,
                    receiveinfo: jsonObj.value[0].text
                });
                $scope.$apply();
            };

            //----------------------------------------------------
            $scope.vmIsHostSelected = function (index) {
                return $scope.currentHost.index == index;
            }

            $scope.vmIsHostSTP = function (index) {
                return $scope.hostList[index].external_device_id == -1;
            }

            $scope.vmHostClick = function (index) {
                return $scope.currentHost.index = index;
            };

            $scope.vmSendEditHost = function () {
                $.ajax({
                    url: '/',
                    type: 'GET',
                    timeout: $scope.timeOut,
                    scriptCharset: 'windows-1251',
                    dataType: 'json',
                    data: {
                        command: 'edithost',
                        ip: $scope.currentHost.ip_address,
                        id: $scope.currentHost.external_device_id,
                        host: window.location.host
                    },
                    error: function (jqxhr, status, errorMsg, response) {
                        vmAddLog({
                            "value": [{
                                host: host,
                                command: command,
                                status: 'error',
                                info: '',
                                text: errorMsg + ' <p>An error has occurred:</p> ' + response
                            }]
                        });
                    },
                    success: function (data, status, jqxhr) {
                        vmAddLog(data);
                    }
                });
            };

            $scope.vmEdtHost = function () {
                if (($scope.currentHost.index == -1)||($scope.hostList[$scope.currentHost.index].external_device_id == -1)) {
                    return
                }
                ;

                $scope.currentHost.ip_address = $scope.hostList[$scope.currentHost.index].ip_address;
                $scope.currentHost.external_device_id = $scope.hostList[$scope.currentHost.index].external_device_id;

                var edHost = $('#edHostName');
                edHost.css({'display': 'inline'});
                edHost.dialog({
                    resizable: false,
                    height: 'auto',
                    width: 300,
                    //minWidth: 550,
                    closeOnEscape: true,
                    modal: true,
                    buttons: [
                        {
                            text: jQuery.fn.vmGetTranslate('ok', $scope.currentLang),
                            click: function () {
                                $scope.vmSendEditHost();
                                $scope.hostList[$scope.currentHost.index].ip_address = $scope.currentHost.ip_address;
                                $(this).dialog('close');
                            }
                        },
                        {
                            text: jQuery.fn.vmGetTranslate('cancel', $scope.currentLang),
                            click: function () {
                                $(this).dialog('close');
                            }
                        }
                    ]
                });
                edHost.dialog('option', 'title', jQuery.fn.vmGetTranslate('edithost', $scope.currentLang));
            };
        }
    )
    ;

