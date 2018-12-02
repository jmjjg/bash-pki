- https://pki-tutorial.readthedocs.io/en/latest/simple/
- https://bitbucket.org/stefanholek/pki-example-1/downloads/
- https://itigloo.com/security/change-openssl-default-signature-algorithm/
- https://kupczynski.info/2013/04/21/creating-your-own-certificates.html
- https://superuser.com/questions/226192/avoid-password-prompt-for-keys-and-prompts-for-dn-information
- https://security.stackexchange.com/questions/106525/generate-csr-and-private-key-with-password-with-openssl

- https://security.stackexchange.com/questions/177509/purpose-of-randfile-in-openssl
    - `openssl rand -base64 -out randfile 666`
- https://mta.openssl.org/pipermail/openssl-users/2017-August/006351.html
- https://gist.github.com/Soarez/9688998

```bash
sudo chown -R cbuffin: . \
    && docker-compose build app \
    && docker-compose run app /bin/bash
```

```bash
sudo chown -R cbuffin: . \
    && docker-compose run app /bin/bash
```

```bash
sudo chown -R cbuffin: . \
    && sudo rm -rf opt/*
```
