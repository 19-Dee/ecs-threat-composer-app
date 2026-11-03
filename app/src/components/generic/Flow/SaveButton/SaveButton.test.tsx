import { fireEvent, render, screen } from '@testing-library/react';
import SaveButton from './SaveButton';

Object.defineProperty(window.performance, 'mark', {
  configurable: true,
  value: jest.fn(),
});

describe('SaveButton', () => {
  it('calls the save handler when there are unsaved changes', () => {
    const saveHandler = jest.fn();

    render(<SaveButton saveHandler={saveHandler} saveState={false} />);
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    expect(saveHandler).toHaveBeenCalledTimes(1);
  });

  it('is disabled after the changes have been saved', () => {
    const saveHandler = jest.fn();

    render(<SaveButton saveHandler={saveHandler} saveState />);

    expect(screen.getByRole('button', { name: 'Saved' })).toBeDisabled();
    expect(saveHandler).not.toHaveBeenCalled();
  });
});
