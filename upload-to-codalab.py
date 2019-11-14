#!/usr/bin/env python3

# One-time script to upload all the contents of MLcomp to CodaLab.

import os
import re
import sys
import shlex
import yaml
import json

pretend = False

def bundle_name(type, id):
    return 'mlcomp-' + type + '-' + id

def worksheet_name(domain, type):
    return 'mlcomp-' + domain + '-' + type + 's'

home = 'home-mlcomp'

def system(command, allow_fail=False):
    print(command)
    if not pretend:
        if os.system(command) != 0 and not allow_fail:
            sys.exit(1)

def upload(path, name, description, tags, worksheet):
    system('cl upload {} --name {} --description {} --tags {} -w {}'.format(path, name, shlex.quote(description), ' '.join(tags), worksheet))

def add_text(text, worksheet):
    system('cl add text {} {}'.format(shlex.quote(text), worksheet))

def add_subworksheet(subworksheet, worksheet):
    system('cl add worksheet {} {}'.format(subworksheet, worksheet))

with open('domains/index') as f:
    domains = yaml.load(f)

def domain_url(domain):
    return 'https://github.com/percyliang/mlcomp/blob/master/domains/{}.domain'.format(domain)

def create_main_page():
    for domain in domains:
        add_text('', home)
        add_text('## [{}]({})'.format(domain, domain_url(domain)), home)
        with open(os.path.join('domains', domain + '.domain')) as f:
            domain_info = yaml.load(f)
        add_text(domain_info['taskDescription'], home)
        for type in ['program', 'dataset']:
            system('cl new {}'.format(worksheet_name(domain, type)), allow_fail=True)
            add_subworksheet(worksheet_name(domain, type), home)
            create_domain_type_page(domain, type)

def create_domain_type_page(domain, type):
    worksheet = worksheet_name(domain, type)
    title = domain + ' ' + type + 's'
    system('cl wedit {} --title {}'.format(worksheet, shlex.quote(title)))
    add_text('This worksheet contains the list of MLcomp {}s from the [{} domain]({}).'.format(type, domain, domain_url(domain)), worksheet)

def create_bundles(type):
    base_path = os.path.join('var', type + 's')
    names = os.listdir(base_path)
    names = [name for name in names if re.match('^\d+$', name)]
    names = map(str, sorted(map(int, names)))
    for name in names:
        path = os.path.join(base_path, name)
        create_bundle(type, path)

def is_spam(s):
    # If it contains too many URLs
    return len(s.split('http://')) > 3 or len(s.split('https://')) > 3

# id -> program|dataset -> {name, domain}
# So that when we read the runs, we can associate.
infos = {'program': {}, 'dataset': {}}

def create_bundle(type, path):
    if type == 'run':
        try:
            readme_path = os.path.join(path, 'README')
            if not os.path.exists(readme_path):
                readme_path = os.path.join(path, 'info')
            with open(readme_path) as f:
                contents = f.read()
        except:
            print('ERROR loading {}, skipping'.format(readme_path))
            return
        if is_spam(contents):
            print('ERROR: {} looks like spam'.format(readme_path))
            return
        program_id = None
        dataset_id = None
        # Format:
        # program0: supervised-learning (id=1, created by internal) [Main entry for supervised learning for training and testing a program on a dataset.]
        # program1: tune-hyperparameter (id=42, created by internal) [Sets the hyperparameter]
        # program3: simple-naive-bayes (id=97, created by pliang) [A Simple Naive Bayes implementation in Ruby.]
        # program4: binary-utils (id=3, created by internal) [Validates and inspects a dataset in BinaryClassification format.]
        # program5: classification-evaluator (id=7, created by internal) [Evaluates predictions of classification datasets (discrete outputs).]
        # dataset6: svmlight-example1 (id=237, created by internal) [Example 1 from SVMlight software]
        # program7: binary-utils (id=3, created by internal) [Validates and inspects a dataset in BinaryClassification format.]
        # program8: classification-evaluator (id=7, created by internal) [Evaluates predictions of classification datasets (discrete outputs).]
        for line in contents.split('\n'):
            m = re.match('^(program|dataset)\d: .+ \(id=(\d+)', line)
            if m:
                id = m.group(2)
                if m.group(1) == 'program':
                    if id in infos['program'] and infos['program'][id]['domain'] in domains:
                        program_id = id
                if m.group(1) == 'dataset':
                    if id in infos['dataset'] and infos['dataset'][id]['domain'] in domains:
                        dataset_id = id

        # Would ideally like to perform the run, but that's too much work
        if program_id is None or dataset_id is None:
            print('ERROR: {} has invalid program or dataset id: {} {}'.format(path, program_id, dataset_id))
            return
        name = 'mlcomp-run'
        description = infos['program'][program_id]['name'] + ' ON ' + infos['dataset'][dataset_id]['name']
        domain = infos['dataset'][dataset_id]['domain']
    else:
        try:
            metadata_path = os.path.join(path, 'metadata')
            with open(metadata_path) as f:
                info = yaml.load(f)
        except:
            print('ERROR loading {}, skipping'.format(metadata_path))
            return

        if info and 'format' in info:
            domain = info['format']
        elif info and 'task' in info:
            domain = info['task']
        else:
            print('ERROR: {} has weird info {}, skipping'.format(metadata_path, info))
            return

        name = 'mlcomp-' + type + '-' + re.sub('[^\w_]', '_', info['name']).replace('__', '_')
        description = info.get('description', '')
        if is_spam(description):
            print('ERROR: {} looks like spam'.format(metadata_path))
            return

    if domain not in domains:
        print('ERROR: invalid domain {}'.format(domain))
        return

    if type != 'run':
        id = os.path.basename(path)
        infos[type][id] = {
            'domain': domain,
            'name': name,
        }

    tags = ['mlcomp', type, domain]
    print('CREATE {} {} {} {} | {}'.format(domain, type, path, name, description))
    worksheet = worksheet_name(domain, type)
    upload(path, name=name, description=description, tags=tags, worksheet=worksheet)

#create_main_page()
create_bundles('dataset')
#create_bundles('program')
#with open('infos.json', 'w') as f:
    #json.dump(infos, f)

# Too many runs, don't do this
#with open('infos.json') as f:
    #infos = json.load(f)
#create_bundles('run')
