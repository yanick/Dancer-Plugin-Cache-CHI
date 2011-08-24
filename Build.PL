
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Dancer::Test' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Dancer plugin to cache response content (and anything else)',
  'dist_author' => [
    'Yanick Champoux <yanick@cpan.org>'
  ],
  'dist_name' => 'Dancer-Plugin-Cache-CHI',
  'dist_version' => '1.1.0',
  'license' => 'perl',
  'module_name' => 'Dancer::Plugin::Cache::CHI',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'CHI' => '0',
    'Dancer' => '1.1904',
    'Dancer::Plugin' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
