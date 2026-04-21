# 🏛️ IASD - projeto de extensão universitária (beta 2)

sistema web desenvolvido para a Igreja Adventista do Sétimo Dia (IASD) do bairro "Deus É Fiel" de Toritama/PE, como projeto de extensão focado na comunidade. esta é a versão **beta 2** do repositório.

## 📋 sumário

- [visão geral](#visão-geral)
- [funcionalidades](#funcionalidades)
- [tecnologias](#tecnologias)
- [estrutura do projeto](#estrutura-do-projeto)
- [configuração do supabase](#configuração-do-supabase)
- [deploy](#deploy)
- [acessibilidade](#acessibilidade)
- [segurança e privacidade](#segurança-e-privacidade)

---

## 🎯 visão geral

este projeto visa criar e aprimorar uma plataforma digital acessível para uma igreja adventista local, conectando membros, voluntários e líderes. o sistema foi projetado com foco especial em **acessibilidade para idosos**, garantindo usabilidade através de:

no modo de acessibilidade:
- fontes grandes e legíveis
- alto contraste de cores
- botões grandes (área de toque mínima de 60px)
- navegação simples e intuitiva

no geral:
- modo noturno manual ou automático
  - ao pôr do sol ativando automaticamente
  - ao nascer do sol desativando automaticamente
- cores oficiais da Igreja Adventista do Sétimo Dia
- modo anônimo ou logado como membro ou lider no site

---

## ✨ funcionalidades

### 🏠 página inicial
- boas-vindas com design limpo
- botões de ação rápida ("pedir oração", "preciso de ajuda")
- visão geral dos serviços oferecidos
- pedidos de oração recentes

### ℹ️ sobre a IASD
- informações institucionais e serviços à comunidade
- crenças fundamentais, missão e visão

### 🤝 voluntariado
- **cadastro de voluntários**: membros podem se inscrever em diversas áreas
- **área de saúde/enfermagem**: fluxo específico para acompanhamento
- **solicitação de acompanhamento**: idosos podem solicitar auxílio de saúde
- dados sensíveis protegidos e acessível somente por lideres (endereço, condições médicas, etc)

### 📅 agendamento de estudos bíblicos
- escolha de data e horário (presencial ou online)
- endereço protegido (visível apenas para líderes)
- link integrado para reuniões online

### 🙏 mural de orações
- **privacidade configurável**:
  - **público**: todos podem ver e orar
  - **anônimo**: todos veem, mas não sabem quem pediu
  - **apenas líderes**: somente a liderança recebe
- contador de orações e botão "eu vou orar"

### 📞 contato
- formulário de mensagens e contatos da liderança

---

## 🛠️ tecnologias

### frontend
- **HTML5** semântico
- **CSS3** com variáveis CSS
- **JS** vanilla (ES6+)
- ícones otimizados

### backend
- **supabase** (BaaS)
  - autenticação
  - banco de dados PostgreSQL
  - Row Level Security (RLS)
  - real-time subscriptions

### hospedagem e deploy
- **vercel** (recomendado para integração contínua)
- **github pages**

---

## 📁 estrutura do projeto

```text
iasd-beta2/
├── index.html              # página inicial
├── sobre.html              # sobre a IASD
├── voluntariado.html       # sistema de voluntariado
├── agendamento.html        # agendamento de estudos
├── oracoes.html            # mural de orações
├── contato.html            # página de contato
├── css/
│   ├── style.css           # estilos principais
│   └── components.css      # componentes reutilizáveis
├── js/
│   └── supabase-client.js  # cliente e funções da API
├── database/
│   └── schema.sql          # schema completo do banco
└── README.md               # esta documentação
