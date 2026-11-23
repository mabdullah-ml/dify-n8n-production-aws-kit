# Dify & n8n AWS本番構築キット＆業務ワークフロー集

> 🌐 **[English Documentation (README.md)](./README.md)**

AWS上に **Dify および n8n をセキュアにセルフホストするための Terraform IaC**（VPC・ECS・Aurora PostgreSQL Serverless v2・暗号化S3・Secrets Manager）と、CI自動検証済みの **Dify DSL YAML／n8n JSON ワークフロー設計テンプレート集**（RAGサポート・AIコマース・夜間KB自動同期）をまとめたFDE向けスターターキットです。

```bash
python scripts/validate_blueprints.py blueprints
pytest -v
```

**作成者:** あぶどら・まもん（工学博士 / PMP） · [GitHub](https://github.com/mabdullah-ml) · [LinkedIn](https://www.linkedin.com/in/mamunabdullah01)
