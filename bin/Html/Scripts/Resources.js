(function ($) {
    var translations;
    this.currentLang = navigator.language.split('-')[0] || navigator.userLanguage.split('-')[0];

    translations = {
        en: {
            clear: 'Clear',
            command: 'Command',
            execute: 'Execute',
            edit: 'Edit',
            host: 'Host',
            login: 'Login',
            logout: 'Logout',
            filter: 'Filter',
            ok: 'Ok',
            cancel: 'Cancel',
            mnuexecsql: 'Run SQL-script',
            mnuexecsqlfile: 'Run SQL-script file',
            mnuexecutecmd: 'Run command cmd',
            mnuexecutecmdfile: 'Run command with cmd file',
            mnuinfofile: 'Get file information',
            mnuinfostatus: 'Get status',
            mnumessage: 'Send message',
            mnuparamcfgdel: 'Delete option cfg',
            mnuparamcfgget: 'Get option cfg',
            mnuparamcfgset: 'Set option cfg',
            mnureceivefile: 'Receive file',
            mnurefresh: 'Update group of directory',
            mnuremoteact: 'Remote act',
            mnusendfile: 'Send file',
            mnuservicereload: 'Restart service',
            mnuservicestop: 'Stop service',
            mnutransfer: 'Checks service',
            password: 'Password',
            receiveinfo: 'Receive info',
            registration: 'Registration',
            result: 'Result',
            results: 'Results:',
            remotecontrol: 'Remote control',
            sendinfo: 'Send info',
            status: 'Status',
            time: 'Time',
            cmdsql: 'SQL text',
            cmdcmd: 'Cmd text',
            cmdinfo: 'File name',
            cmdstatus: 'Status',
            cmdmessage: 'Message',
            cmdcfg: 'Cgf parameters',
            cmdfile: 'File name or mask',
            cmdrefresh: 'Number or name of directory',
            cmdsendfile: 'File path and name',
            sep: '-'.repeat(25),
            edithost: 'Edit ��-address',
            ipaddress: 'IP address'
        },

        ru: {
            clear: '��������',
            command: '�������',
            execute: '��������� �������',
            edit: '�������������',
            host: '����',
            login: '������������',
            logout: '�����',
            filter: '������',
            ok: 'Ok',
            cancel: '��������',
            mnuexecsql: '��������� SQL-������',
            mnuexecsqlfile: '��������� SQL-������ �� �����',
            mnuexecutecmd: '��������� ������� cmd ',
            mnuexecutecmdfile: '��������� ������� cmd �� �����',
            mnuinfofile: '�������� ���������� � �����',
            mnuinfostatus: '�������� ������',
            mnumessage: '������� ���������',
            mnuparamcfgdel: '������� �������� cfg',
            mnuparamcfgget: '�������� �������� cfg',
            mnuparamcfgset: '���������� �������� cfg',
            mnureceivefile: '������� ����',
            mnurefresh: '�������� ������ ������������',
            mnuremoteact: '��������� �������� �� ���',
            mnusendfile: '�������� ����',
            mnuservicereload: '������������� �����',
            mnuservicestop: '���������� �����',
            mnutransfer: '�������� ����',
            password: '������',
            receiveinfo: '��������',
            registration: '�����������',
            result: '��������� ����������',
            results: '��������� ���������� ������:',
            remotecontrol: '��������� ����������',
            sendinfo: '����������',
            status: '������',
            time: '�����',
            cmdsql: '����� �������',
            cmdcmd: '����� cmd ',
            cmdinfo: '��� �����',
            cmdstatus: '������',
            cmdmessage: '����� ���������',
            cmdcfg: '�������� ��������� cgf',
            cmdfile: '�������� ��� ����� �����',
            cmdrefresh: '����� ��� �������� �����������',
            cmdsendfile: '���� � ��� �����, �� �������� �� ����� �������� �� �������',
            sep: '-'.repeat(25),
            edithost: '������������� ��-������',
            ipaddress: 'IP ������'
        },

        uk: {
            clear: '��������',
            command: '�������',
            execute: '�������� �������',
            edit: '����������',
            host: '����',
            login: '����������',
            logout: '�����',
            filter: 'Գ����',
            ok: 'Ok',
            cancel: '³�������',
            mnuexecsql: '�������� SQL-������',
            mnuexecsqlfile: '�������� SQL-������ � �����',
            mnuexecutecmd: '�������� ������� cmd',
            mnuexecutecmdfile: '�������� ������� cmd � �����',
            mnuinfofile: '�������� ���������� ��� ����',
            mnuinfostatus: '�������� ������',
            mnumessage: '������� �����������',
            mnuparamcfgdel: '�������� �������� cfg',
            mnuparamcfgget: '�������� �������� cfg',
            mnuparamcfgset: '���������� �������� cfg',
            mnureceivefile: '�������� ����',
            mnurefresh: '������� ����� ��������',
            mnuremoteact: '³������� �� �� ���',
            mnusendfile: '�������� ����',
            mnuservicereload: '������������� ����',
            mnuservicestop: '�������� ����',
            mnutransfer: '�������� ����',
            password: '������',
            receiveinfo: '��������',
            registration: '���������',
            result: '��������� ���������',
            results: '��������� ��������� ������:',
            remotecontrol: '³������� ���������',
            sendinfo: '³���������',
            status: '������',
            time: '���',
            cmdsql: '����� �������',
            cmdcmd: '����� cmd',
            cmdinfo: '����� �����',
            cmdstatus: '������',
            cmdmessage: '����� �����������',
            cmdcfg: '����� ��������� cgf',
            cmdfile: '����� ��� ����� �����',
            cmdrefresh: '����� ��� ����� ��������',
            cmdsendfile: '���� � ����� �����, �� ���� �� ���� ���������� �� ������',
            sep: '-'.repeat(25),
            edithost: '���������� ��-������',
            ipaddress: 'IP ������'
        }
    };

    jQuery.fn.vmChangeLang = function vmChangeLang() {
        var lang = $('#langlist :selected').val() || this.currentLang || navigator.language.split('-')[0] || navigator.userLanguage.split('-')[0];
        jQuery.fn.vmTranslate(lang);
    };

    jQuery.fn.vmTranslate = function vmTranslate(lang) {
        this.currentLang = lang || this.currentLang;
        var allElements = document.querySelectorAll('[data-id_phrase]');
        for (var i = 0; i < allElements.length; i++) {
            var attribLang = allElements[i].getAttribute('data-id_phrase').toLowerCase(),
                phraseLang = translations[lang][attribLang];
            allElements[i].innerHTML = phraseLang ? phraseLang : attribLang;
        }
        ;
        if (lang) {
            localStorage['lang'] = lang
        }
        ;

    };

    jQuery.fn.vmGetTranslate = function vmGetTranslate(idPhrase, lang) {
        lang = lang || this.currentLang || navigator.language.split('-')[0] || navigator.userLanguage.split('-')[0];
        return translations[lang][idPhrase];
    };
})
(jQuery);