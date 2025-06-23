# Adhoc APT Repository

```sh
wget -qO - https://apt.dev-adhoc.com/adhoc-devops.asc | sudo gpg --dearmor -o /usr/share/keyrings/adhoc-devops.gpg
echo "deb [signed-by=/usr/share/keyrings/adhoc-devops.gpg]  https://apt.dev-adhoc.com/ stable main" | sudo tee /etc/apt/sources.list.d/adhoc.list
```
