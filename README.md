# lemp-stack
> PHP 7.2 + Nginx Mainline Version + MariaDB 10.2 + Memcached 앱들을 자동 설치합니다.
- 이 스택에서 다루는 방법은 Ubuntu 16.04 에서 검증되었습니다.
- 가장 기본적인 방법으로 apt-get 으로만 설치가 진행 됩니다.
- 이 스택을 설치하는데 필요한 시간은 하드웨어에 따라 다르지만 대략 5분 안입니다.
- 한 번에 LEMP 세팅이 완료가 되고 바로 사이트에 접속 하실 수 있습니다.
- git clone으로 소스를 다운받은 후 스크립트 파일을 열어 환경 변수를 수정해주세요.
- 설치 시 오류나 궁금하신 사항은 sir.kr 에서 gshn을 찾아주세요.

## 설치법

### 1. git clone으로 소스 다운로드
```bash
git clone https://github.com/gshn/lemp-stack
```

### 2. 환경변수 설정
```bash
cd lemp-stack
vim lemp-stack.sh
```

- HOSTNAME="hostname"
> 해당 OS의 호스트을 기입하시면 됩니다. 대체로 실 도메인을 사용합니다.

- DOMAIN="domain.com"
> 서버가 실제로 작동될 도메인을 기입합니다.

- DBROOTPASS="dbrootpass"
> 데이터베이스 root 패스워드를 기입합니다.

- PHPMYADMIN_VERSION="4.7.7"
> https://phpmyadmin.net 에서 가장 최신버전을 확인 후 변경해주세요.

- PHPMYADMIN_BLOWFISH=")Aje8s~9VE|JyV8s7MF0Zw|DReayVcpU^"
> https://www.question-defense.com/tools/phpmyadmin-blowfish-secret-generator 생성된 변수로 변경해주세요.

- PHPMYADMIN_DIRECTORY="phpMyAdmin"
> phpmyadmin이 설치될 디렉터리명을 변경해주세요.

- USERID="userid"
> 호스팅 사용자 아이디

- USERPW="userpw"
> 호스팅 사용자 패스워드

- DOCUMENT_ROOT="/home/${USERID}/app/public"
> 호스팅 DOCUMENT_ROOT 디렉터리 뒤에 app/public 만 필요한대로 수정해주세요.

### 3. 실행권한 변경 및 실행
```bash
chmod 700 lemp-stack.sh
./lemp-stack.sh
```
