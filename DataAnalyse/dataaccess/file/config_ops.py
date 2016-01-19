__author__ = 'xiaoyu'

import ConfigParser


def config_write():
    config = ConfigParser.RawConfigParser()
    config.add_section('Section1')
    config.set('Section1', 'an_int', '15')
    config.set('Section1', 'a_bool', 'true')
    config.set('Section1', 'a_float', '3.1415')
    config.set('Section1', 'baz', 'fun')
    config.set('Section1', 'bar', 'Python')
    config.set('Section1', 'foo', '%(bar)s is %(baz)s!')
    # Writing our configuration file to 'example.cfg'
    with open('example.cfg', 'wb') as configfile:
        config.write(configfile)


def config_reader():
    config = ConfigParser.ConfigParser()
    config.read('example.cfg')
    print config.get('Section1', 'foo', 0)  # -> "Python is fun!"
    print config.get('Section1', 'foo', 1)  # -> "%(bar)s is %(baz)s!"
    # The optional fourth argument is a dict with members that will take
    # precedence in interpolation.
    print config.get('Section1', 'foo', 0, {'bar': 'Documentation',
                                        'baz': 'evil'})


def opt_move(config, section1, section2, option):
    try:
        config.set(section2, option, config.get(section1, option, 1))
    except ConfigParser.NoSectionError:
        # Create non-existent section
        config.add_section(section2)
        opt_move(config, section1, section2, option)
    else:
        config.remove_option(section1, option)

def config_remove():
    config = ConfigParser.SafeConfigParser({'bar': 'Life', 'baz': 'hard'})
    config.read('example.cfg')
    print config.get('Section1', 'foo') # -> "Python is fun!"
    config.remove_option('Section1', 'bar')
    config.remove_option('Section1', 'baz')
    print config.get('Section1', 'foo') # -> "Life is hard!"


if __name__ == '__main__':
    config_write()
    config_reader()
    config_remove()