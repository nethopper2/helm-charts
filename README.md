# Helm Charts Repository

## Overview

This repository contains a collection of Nethopper Helm Charts for deployment on Kubernetes clusters.

## Requirements

- Kubernetes 1.22+
- Helm 3.0+

## Repository Installation

To add this repository to your local Helm configuration, run:

```bash
helm repo add nh-charts helm repo add nh-charts https://raw.githubusercontent.com/nethopper2/helm-charts/gh-pages/ --username <gh-username> --password <token>
helm repo update
```

## Available Charts

- `example`

## Chart Installation

To install one of the available charts, run:

```bash
helm install [release-name] [YourRepoName]/[chart-name]
```

## Configuration

Each chart comes with its own set of configurable parameters. Please refer to the individual chart's documentation for more information.

helm repo update
```

## Available Charts

- `example`

## Chart Installation

To install one of the available charts, run:

```bash
helm install [release-name] [YourRepoName]/[chart-name]
```

## Configuration

Each chart comes with its own set of configurable parameters. Please refer to the individual chart's documentation for more information.
