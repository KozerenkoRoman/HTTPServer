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
            edithost: 'Edit ІР-address',
            ipaddress: 'IP address'
        },

        ru: {
            clear: 'Очистить',
            command: 'Команда',
            execute: 'Выполнить команду',
            edit: 'Редактировать',
            host: 'Хост',
            login: 'Пользователь',
            logout: 'Выйти',
            filter: 'Фильтр',
            ok: 'Ok',
            cancel: 'Отменить',
            mnuexecsql: 'Выполнить SQL-скрипт',
            mnuexecsqlfile: 'Выполнить SQL-скрипт из файла',
            mnuexecutecmd: 'Выполнить команду cmd ',
            mnuexecutecmdfile: 'Выполнить команду cmd из файла',
            mnuinfofile: 'Получить информацию о файле',
            mnuinfostatus: 'Получить статус',
            mnumessage: 'Послать сообщение',
            mnuparamcfgdel: 'Удалить параметр cfg',
            mnuparamcfgget: 'Получить параметр cfg',
            mnuparamcfgset: 'Установить параметр cfg',
            mnureceivefile: 'Принять файл',
            mnurefresh: 'Обновить группу справочников',
            mnuremoteact: 'Удаленное действие на ПОС',
            mnusendfile: 'Передать файл',
            mnuservicereload: 'Перезапустить обмен',
            mnuservicestop: 'Остановить обмен',
            mnutransfer: 'Передать чеки',
            password: 'Пароль',
            receiveinfo: 'Получено',
            registration: 'Регистрация',
            result: 'Результат выполнения',
            results: 'Результат выполнения команд:',
            remotecontrol: 'Удаленное управление',
            sendinfo: 'Отправлено',
            status: 'Статус',
            time: 'Время',
            cmdsql: 'Текст скрипта',
            cmdcmd: 'Текст cmd ',
            cmdinfo: 'Имя файла',
            cmdstatus: 'Статус',
            cmdmessage: 'Текст сообщения',
            cmdcfg: 'Название параметра cgf',
            cmdfile: 'Название или маска файла',
            cmdrefresh: 'Номер или название справочника',
            cmdsendfile: 'Путь и имя файла, по которому он будет сохранен на сервере',
            sep: '-'.repeat(25),
            edithost: 'Редактировать ІР-адресс',
            ipaddress: 'IP адресс'
        },

        uk: {
            clear: 'Очистити',
            command: 'Команда',
            execute: 'Виконати команду',
            edit: 'Редагувати',
            host: 'Хост',
            login: 'Користувач',
            logout: 'Вийти',
            filter: 'Фільтр',
            ok: 'Ok',
            cancel: 'Відхилити',
            mnuexecsql: 'Виконати SQL-скрипт',
            mnuexecsqlfile: 'Виконати SQL-скрипт з файла',
            mnuexecutecmd: 'Виконати команду cmd',
            mnuexecutecmdfile: 'Виконати команду cmd з файла',
            mnuinfofile: 'Отримати інформацію про файл',
            mnuinfostatus: 'Отримати статус',
            mnumessage: 'Послати повідомлення',
            mnuparamcfgdel: 'Видалити параметр cfg',
            mnuparamcfgget: 'Отримати параметр cfg',
            mnuparamcfgset: 'Встановити параметр cfg',
            mnureceivefile: 'Прийняти файл',
            mnurefresh: 'Оновити групу довідників',
            mnuremoteact: 'Віддалена дія на ПОС',
            mnusendfile: 'Передати файл',
            mnuservicereload: 'Перезапустити обмін',
            mnuservicestop: 'Зупинити обмін',
            mnutransfer: 'Передати чеки',
            password: 'Пароль',
            receiveinfo: 'Отримано',
            registration: 'Реєстрація',
            result: 'Результат виконання',
            results: 'Результат виконання команд:',
            remotecontrol: 'Віддалене керування',
            sendinfo: 'Відправлено',
            status: 'Статус',
            time: 'Час',
            cmdsql: 'Текст скрипта',
            cmdcmd: 'Текст cmd',
            cmdinfo: 'Назва файла',
            cmdstatus: 'Статус',
            cmdmessage: 'Текст повідомлення',
            cmdcfg: 'Назва параметра cgf',
            cmdfile: 'Назва або маска файла',
            cmdrefresh: 'Номер або назва довідника',
            cmdsendfile: 'Шлях і назва файла, за яким він буде збережений на сервері',
            sep: '-'.repeat(25),
            edithost: 'Редагувати ІР-адресу',
            ipaddress: 'IP адреса'
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